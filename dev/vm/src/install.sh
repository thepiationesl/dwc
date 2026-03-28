#!/usr/bin/env bash
set -Eeuo pipefail

TMP="$STORAGE/tmp"
BOOT=""
ISO=""
CUSTOM=""

# Windows ISO download URLs (Microsoft official)
getDownloadUrl() {
    local version="$1"
    local lang="$2"
    local url=""
    
    # Use Microsoft's download API or known links
    case "${version,,}" in
        "win10x64" | "win10" )
            # Windows 10 Multi-edition ISO
            url="https://software.download.prss.microsoft.com/dbazure/Win10_22H2_Chinese_Simplified_x64v1.iso"
            ;;
        "win11x64" | "win11" )
            url="https://software.download.prss.microsoft.com/dbazure/Win11_23H2_Chinese_Simplified_x64v2.iso"
            ;;
        "win10x64-enterprise-ltsc-eval" )
            url="https://software.download.prss.microsoft.com/dbazure/en-us_windows_10_enterprise_ltsc_2021_x64_dvd_d289cf96.iso"
            ;;
    esac
    
    echo "$url"
}

# Check if installation can be skipped
skipInstall() {
    local iso="$1"
    local boot="$STORAGE/windows.boot"
    
    # If boot marker exists and disk exists, skip
    [ -f "$boot" ] && hasDisk && return 0
    
    # If ISO exists, don't skip
    [ -f "$iso" ] && [ -s "$iso" ] && return 1
    
    return 1
}

# Start installation process
startInstall() {
    info "Checking installation status..."
    
    # Check for custom ISO
    detectCustom
    
    # Determine boot ISO path
    if [ -z "$CUSTOM" ]; then
        local lang
        lang=$(getLanguage "$LANGUAGE" "code")
        BOOT="$STORAGE/${VERSION}_${lang}.iso"
    else
        BOOT="$CUSTOM"
    fi
    
    # Skip if already installed
    if skipInstall "$BOOT"; then
        info "Windows already installed, skipping setup"
        return 1
    fi
    
    # Create temp directory
    rm -rf "$TMP"
    makeDir "$TMP"
    
    # Download ISO if needed
    if [ ! -f "$BOOT" ] || [ ! -s "$BOOT" ]; then
        downloadIso
    fi
    
    # Extract drivers
    extractDrivers
    
    # Create disk
    createDisk "$DISK_FILE" "$DISK_SIZE" "qcow2"
    
    # Setup EFI
    setupEfi
    
    # Prepare installation ISO (add drivers, autounattend)
    if [[ "$MANUAL" != [Yy1]* ]]; then
        prepareIso
    fi
    
    return 0
}

# Download Windows ISO
downloadIso() {
    local url
    url=$(getDownloadUrl "$VERSION" "$LANGUAGE")
    
    if [ -z "$url" ]; then
        error "No download URL for version: $VERSION"
        error "Please provide a custom ISO in /storage/"
        return 1
    fi
    
    info "Downloading Windows ISO..."
    info "URL: $url"
    
    download "$url" "$BOOT" "Windows ISO" || {
        error "Failed to download Windows ISO"
        return 1
    }
    
    setOwner "$BOOT"
    info "Download complete: $BOOT"
}

# Detect custom ISO files
detectCustom() {
    CUSTOM=""
    
    # Check for custom.iso or boot.iso
    local custom
    custom=$(find "$STORAGE" -maxdepth 1 -type f \( -iname "custom.iso" -o -iname "boot.iso" -o -iname "*.iso" \) -print -quit 2>/dev/null)
    
    if [ -n "$custom" ] && [ -f "$custom" ]; then
        CUSTOM="$custom"
        info "Found custom ISO: $CUSTOM"
    fi
}

# Prepare ISO with drivers and autounattend (for auto install)
prepareIso() {
    [ -z "$BOOT" ] && return 1
    [ ! -f "$BOOT" ] && return 1
    
    info "Preparing installation ISO..."
    
    local src="$TMP/iso"
    local dst="$TMP/new"
    
    # Extract ISO
    makeDir "$src"
    makeDir "$dst"
    
    7z x -o"$src" "$BOOT" &>/dev/null || bsdtar -xf "$BOOT" -C "$src" || {
        warn "Failed to extract ISO, using original"
        return 0
    }
    
    # Copy to new directory
    cp -r "$src"/* "$dst"/
    
    # Add VirtIO drivers
    if [ -d "/var/drivers" ]; then
        cp -r /var/drivers/* "$dst"/ 2>/dev/null || true
    fi
    
    # Add autounattend.xml for automatic installation
    if [[ "$MANUAL" != [Yy1]* ]]; then
        createAutounattend "$dst"
    fi
    
    # Rebuild ISO
    local label="DVDIMAGE"
    genisoimage -quiet -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
        -iso-level 2 -udf -joliet -D -N -relaxed-filenames \
        -V "$label" -o "$BOOT.new" "$dst" 2>/dev/null || {
        warn "Failed to rebuild ISO, using original"
        rm -rf "$TMP"
        return 0
    }
    
    mv -f "$BOOT.new" "$BOOT"
    rm -rf "$TMP"
    
    info "ISO prepared with drivers"
}

# Create autounattend.xml for automatic installation
createAutounattend() {
    local dir="$1"
    local file="$dir/autounattend.xml"
    
    local lang
    lang=$(getLanguage "$LANGUAGE" "culture")
    
    cat > "$file" << EOF
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage>
                <UILanguage>$lang</UILanguage>
            </SetupUILanguage>
            <InputLocale>$lang</InputLocale>
            <SystemLocale>$lang</SystemLocale>
            <UILanguage>$lang</UILanguage>
            <UserLocale>$lang</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>EFI</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>MSR</Type>
                            <Size>128</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>3</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Format>FAT32</Format>
                            <Label>System</Label>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>3</PartitionID>
                            <Format>NTFS</Format>
                            <Label>Windows</Label>
                            <Letter>C</Letter>
                        </ModifyPartition>
                    </ModifyPartitions>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>3</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>cmd /c reg add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>false</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
EOF

    # Add user account if specified
    if [ -n "$USERNAME" ]; then
        cat >> "$file" << EOF
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>$USERNAME</Name>
                        <Group>Administrators</Group>
                        <Password>
                            <Value>${PASSWORD:-}</Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>$USERNAME</Username>
                <Password>
                    <Value>${PASSWORD:-}</Value>
                    <PlainText>true</PlainText>
                </Password>
                <LogonCount>1</LogonCount>
            </AutoLogon>
EOF
    fi

    cat >> "$file" << EOF
        </component>
    </settings>
</unattend>
EOF

    info "Created autounattend.xml"
}

return 0

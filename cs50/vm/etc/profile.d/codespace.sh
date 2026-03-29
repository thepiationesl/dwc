# If not root
if [ "$(whoami)" != "root" ]; then

    # Check if running locally and set $RepositoryName if not already set
    if [[ "$CODESPACES" != "true" && -z "$RepositoryName" ]]; then
        export RepositoryName=$(ls -1t --color=never /workspaces | tail -1 | sed 's:/*$::')
        export LOCAL_WORKSPACE_FOLDER="/workspaces/$RepositoryName"
    fi

    # Rewrites URLs of the form http://HOST:PORT as https://$CODESPACE_NAME.app.github.dev:PORT
    _hostname() {

        # If in cloud
        if [[ "$CODESPACES" == "true" ]]; then
            local url="http://[^:]+:(\x1b\[[0-9;]*m)?([0-9]+)(\x1b\[[0-9;]*m)?"
            while read; do
                echo "$REPLY" | sed -E "s#${url}#https://${CODESPACE_NAME}-\2.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}#"
            done

        # Else if local
        else
            tee
        fi
    }

    _version() {
        local version="http-server version:"
        while read; do
            if [[ ! $REPLY =~ ${version} ]]; then
                echo "$REPLY"
            fi
        done
    }

    _prompt() {
        local dir="$(dirs +0)"
        dir="${dir%/}/"
        dir=${dir#"/workspaces/$RepositoryName/"}
        dir="${dir} $ "
        dir=${dir#" "}
        echo -n "${dir}"
    }
    PS1='$(_prompt)'

    alias cd="HOME=\"/workspaces/$RepositoryName\" cd"

    flask() {
        command flask "$@" --host=127.0.0.1 2> >(_hostname >&2)
    }

    diagnose() {
        code /workspaces/$RepositoryName/diagnose.log && \
        cat /etc/issue > diagnose.log && \
        code --list-extensions >> diagnose.log
    }

    http-server() {
        command http-server "$@" | _hostname | _version | uniq
    }
fi

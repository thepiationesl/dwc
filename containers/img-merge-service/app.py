#!/usr/bin/env python3
"""
IMG MERGE SERVICE - 磁盘镜像合并服务
用于在VM容器间同步和合并磁盘镜像文件
"""

import os
import sys
import json
import logging
import hashlib
import tempfile
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

from flask import Flask, request, jsonify, send_file, abort
import requests

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('img-merge-service')

app = Flask(__name__)

# 配置
STORAGE_DIR = os.getenv('STORAGE_DIR', '/storage')
PORT = int(os.getenv('PORT', '8080'))
HOST = os.getenv('HOST', '0.0.0.0')
MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', '10737418240'))  # 10GB默认

# 确保存储目录存在
Path(STORAGE_DIR).mkdir(parents=True, exist_ok=True)

app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH


def calculate_checksum(file_path, chunk_size=8192):
    """计算文件的SHA256校验和"""
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while chunk := f.read(chunk_size):
            sha256.update(chunk)
    return sha256.hexdigest()


def get_file_info(file_path):
    """获取文件信息"""
    path = Path(file_path)
    if not path.exists():
        return None
    
    stat = path.stat()
    return {
        'name': path.name,
        'size': stat.st_size,
        'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
        'checksum': calculate_checksum(file_path)
    }


@app.route('/health', methods=['GET'])
def health_check():
    """健康检查端点"""
    return jsonify({
        'status': 'healthy',
        'service': 'img-merge-service',
        'timestamp': datetime.now().isoformat(),
        'storage': STORAGE_DIR
    })


@app.route('/api/v1/images', methods=['GET'])
def list_images():
    """列出所有可用的磁盘镜像"""
    try:
        images = []
        for ext in ['*.img', '*.qcow2', '*.raw', '*.vmdk', '*.vdi']:
            for file_path in Path(STORAGE_DIR).glob(ext):
                if file_path.is_file():
                    info = get_file_info(file_path)
                    if info:
                        images.append(info)
        
        return jsonify({
            'success': True,
            'images': images,
            'count': len(images)
        })
    except Exception as e:
        logger.error(f"Error listing images: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/images/<filename>', methods=['GET'])
def get_image(filename):
    """下载指定的磁盘镜像"""
    try:
        # 安全检查：防止路径遍历
        if '..' in filename or '/' in filename:
            abort(400, "Invalid filename")
        
        file_path = Path(STORAGE_DIR) / filename
        
        if not file_path.exists():
            abort(404, "Image not found")
        
        if not file_path.is_file():
            abort(400, "Not a file")
        
        logger.info(f"Downloading image: {filename}")
        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename,
            mimetype='application/octet-stream'
        )
    except Exception as e:
        logger.error(f"Error downloading image: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/images/<filename>', methods=['POST', 'PUT'])
def upload_image(filename):
    """上传磁盘镜像"""
    try:
        # 安全检查：防止路径遍历
        if '..' in filename or '/' in filename:
            abort(400, "Invalid filename")
        
        # 检查是否有文件
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No file provided'
            }), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No file selected'
            }), 400
        
        file_path = Path(STORAGE_DIR) / filename
        
        # 创建临时文件
        temp_dir = tempfile.mkdtemp(dir=STORAGE_DIR)
        temp_path = Path(temp_dir) / filename
        
        try:
            # 保存文件到临时位置
            file.save(temp_path)
            
            # 计算校验和
            checksum = calculate_checksum(temp_path)
            
            # 移动到最终位置
            shutil.move(temp_path, file_path)
            
            # 设置适当的权限
            os.chmod(file_path, 0o644)
            
            file_info = get_file_info(file_path)
            if file_info is None:
                file_info = {'size': 0}
            
            logger.info(f"Uploaded image: {filename} (checksum: {checksum})")
            
            return jsonify({
                'success': True,
                'message': 'Image uploaded successfully',
                'filename': filename,
                'checksum': checksum,
                'size': file_info.get('size', 0)
            }), 201
            
        except Exception as e:
            # 清理临时文件
            if temp_path.exists():
                temp_path.unlink()
            if Path(temp_dir).exists():
                Path(temp_dir).rmdir()
            raise e
            
    except Exception as e:
        logger.error(f"Error uploading image: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/images/<filename>', methods=['DELETE'])
def delete_image(filename):
    """删除磁盘镜像"""
    try:
        # 安全检查：防止路径遍历
        if '..' in filename or '/' in filename:
            abort(400, "Invalid filename")
        
        file_path = Path(STORAGE_DIR) / filename
        
        if not file_path.exists():
            abort(404, "Image not found")
        
        if not file_path.is_file():
            abort(400, "Not a file")
        
        file_path.unlink()
        
        logger.info(f"Deleted image: {filename}")
        
        return jsonify({
            'success': True,
            'message': 'Image deleted successfully',
            'filename': filename
        })
    except Exception as e:
        logger.error(f"Error deleting image: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/merge', methods=['POST'])
def merge_images():
    """合并多个磁盘镜像"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        source_images = data.get('source_images', [])
        target_name = data.get('target_name')
        merge_strategy = data.get('strategy', 'concatenate')  # concatenate, overlay, diff
        
        if not source_images:
            return jsonify({
                'success': False,
                'error': 'No source images specified'
            }), 400
        
        if not target_name:
            return jsonify({
                'success': False,
                'error': 'No target name specified'
            }), 400
        
        # 安全检查
        if '..' in target_name or '/' in target_name:
            abort(400, "Invalid target name")
        
        # 验证所有源图像存在
        source_paths = []
        for img in source_images:
            img_path = Path(STORAGE_DIR) / img
            if not img_path.exists():
                return jsonify({
                    'success': False,
                    'error': f'Source image not found: {img}'
                }), 404
            source_paths.append(img_path)
        
        target_path = Path(STORAGE_DIR) / target_name
        
        # 使用qemu-img进行合并（如果可用）
        if merge_strategy == 'concatenate':
            # 简单的文件连接（仅适用于raw格式）
            with open(target_path, 'wb') as outfile:
                for src_path in source_paths:
                    with open(src_path, 'rb') as infile:
                        shutil.copyfileobj(infile, outfile)
        else:
            # 对于其他格式，使用qemu-img convert
            import subprocess
            
            # 创建临时目录用于转换
            temp_dir = tempfile.mkdtemp(dir=STORAGE_DIR)
            temp_target = Path(temp_dir) / target_name
            
            try:
                # 构建qemu-img命令
                cmd = ['qemu-img', 'create', '-f', 'qcow2', '-b']
                
                # 添加backing文件
                backing_file = str(source_paths[0])
                cmd.extend([backing_file, str(temp_target)])
                
                subprocess.run(cmd, check=True, capture_output=True)
                
                # 移动到最终位置
                shutil.move(temp_target, target_path)
                
            except subprocess.CalledProcessError as e:
                logger.error(f"qemu-img failed: {e.stderr.decode()}")
                return jsonify({
                    'success': False,
                    'error': f'qemu-img failed: {e.stderr.decode()}'
                }), 500
            finally:
                # 清理临时目录
                if Path(temp_dir).exists():
                    shutil.rmtree(temp_dir)
        
        # 设置权限
        os.chmod(target_path, 0o644)
        
        file_info = get_file_info(target_path)
        if file_info is None:
            file_info = {'size': 0, 'checksum': ''}
        
        logger.info(f"Merged images into: {target_name}")
        
        return jsonify({
            'success': True,
            'message': 'Images merged successfully',
            'target': target_name,
            'strategy': merge_strategy,
            'size': file_info.get('size', 0),
            'checksum': file_info.get('checksum', '')
        })
        
    except Exception as e:
        logger.error(f"Error merging images: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/pull', methods=['POST'])
def pull_from_remote():
    """从远程VM拉取磁盘镜像"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        remote_url = data.get('remote_url')
        remote_image = data.get('remote_image')
        local_name = data.get('local_name')
        
        if not remote_url:
            return jsonify({
                'success': False,
                'error': 'No remote URL specified'
            }), 400
        
        if not remote_image:
            return jsonify({
                'success': False,
                'error': 'No remote image specified'
            }), 400
        
        # 安全检查
        if '..' in local_name or '/' in local_name:
            abort(400, "Invalid local name")
        
        # 构建远程URL
        if not remote_url.endswith('/'):
            remote_url += '/'
        
        download_url = f"{remote_url}api/v1/images/{remote_image}"
        
        logger.info(f"Pulling image from: {download_url}")
        
        # 下载文件
        response = requests.get(download_url, stream=True, timeout=300)
        response.raise_for_status()
        
        target_path = Path(STORAGE_DIR) / local_name
        
        # 流式写入文件
        with open(target_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        # 设置权限
        os.chmod(target_path, 0o644)
        
        file_info = get_file_info(target_path)
        if file_info is None:
            file_info = {'size': 0, 'checksum': ''}
        
        logger.info(f"Pulled image: {local_name}")
        
        return jsonify({
            'success': True,
            'message': 'Image pulled successfully',
            'local_name': local_name,
            'size': file_info.get('size', 0),
            'checksum': file_info.get('checksum', '')
        })
        
    except requests.RequestException as e:
        logger.error(f"Network error pulling image: {e}")
        return jsonify({
            'success': False,
            'error': f'Network error: {str(e)}'
        }), 500
    except Exception as e:
        logger.error(f"Error pulling image: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/info/<filename>', methods=['GET'])
def get_image_info(filename):
    """获取磁盘镜像的详细信息"""
    try:
        # 安全检查
        if '..' in filename or '/' in filename:
            abort(400, "Invalid filename")
        
        file_path = Path(STORAGE_DIR) / filename
        
        if not file_path.exists():
            abort(404, "Image not found")
        
        file_info = get_file_info(file_path)
        if file_info is None:
            file_info = {'name': filename, 'size': 0, 'modified': '', 'checksum': ''}
        
        # 使用qemu-img获取更多信息
        try:
            result = subprocess.run(
                ['qemu-img', 'info', '--output=json', str(file_path)],
                capture_output=True,
                text=True,
                check=True
            )
            qemu_info = json.loads(result.stdout)
            file_info['qemu_info'] = qemu_info
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            # qemu-img不可用或输出不是JSON
            pass
        
        return jsonify({
            'success': True,
            'image': file_info
        })
    except Exception as e:
        logger.error(f"Error getting image info: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    logger.info(f"Starting IMG MERGE SERVICE on {HOST}:{PORT}")
    logger.info(f"Storage directory: {STORAGE_DIR}")
    
    app.run(
        host=HOST,
        port=PORT,
        debug=os.getenv('DEBUG', 'false').lower() == 'true'
    )

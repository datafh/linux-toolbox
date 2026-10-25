#!/bin/bash
# ============================================================
#  数据渔港 合并工具箱 tools.sh
#  = Linux服务器工具箱(V1.0.4.1) + 轩辕镜像Docker一键安装配置
#  由 linux.sh + docker.sh 合并生成
#  用法: bash tools.sh  （在 Linux 服务器上以 root 或 sudo 运行）
# ============================================================

# ---------- 宝塔数据盘自动挂载（原 auto_disk.sh 全部内容，子 shell 隔离） ----------
auto_disk_main() {
(
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
setup_path=/www
#if [ $1 != "" ];then
	#setup_path=$1;
#fi

#检测磁盘数量
sysDisk=`cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`
if [ "${sysDisk}" == "" ]; then
	echo -e "ERROR!This server has only one hard drive,exit"
	echo -e "此服务器只有一块磁盘,无法挂载"
	echo -e "Bye-bye"
	exit;
fi
#检测/www目录是否已挂载磁盘
mountDisk=`df -h | awk '{print $6}' |grep www`
if [ "${mountDisk}" != "" ]; then
	echo -e "www directory has been mounted,exit"
	echo -e "www目录已被挂载,不执行任何操作"
	echo -e "Bye-bye"
	exit;
fi
#检测是否有windows分区
winDisk=`fdisk -l |grep "NTFS\|FAT32"`
if [ "${winDisk}" != "" ];then
	echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
	echo "危险 数据盘为windwos分区，为了你的数据安全，请手动挂载，本脚本不执行任何操作。"
	exit;
fi
echo "
+----------------------------------------------------------------------
| Bt-WebPanel Automatic disk partitioning tool
+----------------------------------------------------------------------
| Copyright © 2015-2017 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| Auto mount partition disk to $setup_path
+----------------------------------------------------------------------
"


#数据盘自动分区
fdiskP(){
	
	for i in `cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`;
	do
		#判断指定目录是否被挂载
		isR=`df -P|grep $setup_path`
		if [ "$isR" != "" ];then
			echo "Error: The $setup_path directory has been mounted."
			return;
		fi
		
		isM=`df -P|grep '/dev/${i}1'`
		if [ "$isM" != "" ];then
			echo "/dev/${i}1 has been mounted."
			continue;
		fi
			
		#判断是否存在未分区磁盘
		isP=`fdisk -l /dev/$i |grep -v 'bytes'|grep "$i[1-9]*"`
		if [ "$isP" = "" ];then
				#开始分区
				fdisk -S 56 /dev/$i << EOF
n
p
1


wq
EOF

			sleep 5
			#检查是否分区成功
			checkP=`fdisk -l /dev/$i|grep "/dev/${i}1"`
			if [ "$checkP" != "" ];then
				#格式化分区
				mkfs.ext4 /dev/${i}1
				mkdir $setup_path
				#挂载分区
				sed -i "/\/dev\/${i}1/d" /etc/fstab
				echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
				mount -a
				df -h
			fi
		else
			#判断是否存在Windows磁盘分区
			isN=`fdisk -l /dev/$i|grep -v 'bytes'|grep -v "NTFS"|grep -v "FAT32"`
			if [ "$isN" = "" ];then
				echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
				return;
			fi
			
			#挂载已有分区
			checkR=`df -P|grep "/dev/$i"`
			if [ "$checkR" = "" ];then
					mkdir $setup_path
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
					mount -a
					df -h
			fi
			
			#清理不可写分区
			echo 'True' > $setup_path/checkD.pl
			if [ ! -f $setup_path/checkD.pl ];then
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					mount -a
					df -h
			else
					rm -f $setup_path/checkD.pl
			fi
		fi
	done
}
stop_service(){

	/etc/init.d/bt stop

	if [ -f "/etc/init.d/nginx" ]; then
		/etc/init.d/nginx stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/httpd" ]; then
		/etc/init.d/httpd stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/mysqld" ]; then
		/etc/init.d/mysqld stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/pure-ftpd" ]; then
		/etc/init.d/pure-ftpd stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/tomcat" ]; then
		/etc/init.d/tomcat stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/redis" ]; then
		/etc/init.d/redis stop > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/memcached" ]; then
		/etc/init.d/memcached stop > /dev/null 2>&1
	fi

	if [ -f "/www/server/panel/data/502Task.pl" ]; then
		rm -f /www/server/panel/data/502Task.pl
		if [ -f "/etc/init.d/php-fpm-52" ]; then
			/etc/init.d/php-fpm-52 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-53" ]; then
			/etc/init.d/php-fpm-53 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-54" ]; then
			/etc/init.d/php-fpm-54 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-55" ]; then
			/etc/init.d/php-fpm-55 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-56" ]; then
			/etc/init.d/php-fpm-56 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-70" ]; then
			/etc/init.d/php-fpm-70 stop > /dev/null 2>&1
		fi

		if [ -f "/etc/init.d/php-fpm-71" ]; then
			/etc/init.d/php-fpm-71 stop > /dev/null 2>&1
		fi
	fi
}

start_service()
{
	/etc/init.d/bt start

	if [ -f "/etc/init.d/nginx" ]; then
		/etc/init.d/nginx start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/httpd" ]; then
		/etc/init.d/httpd start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/mysqld" ]; then
		/etc/init.d/mysqld start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/pure-ftpd" ]; then
		/etc/init.d/pure-ftpd start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/tomcat" ]; then
		/etc/init.d/tomcat start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/redis" ]; then
		/etc/init.d/redis start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/memcached" ]; then
		/etc/init.d/memcached start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-52" ]; then
		/etc/init.d/php-fpm-52 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-53" ]; then
		/etc/init.d/php-fpm-53 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-54" ]; then
		/etc/init.d/php-fpm-54 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-55" ]; then
		/etc/init.d/php-fpm-55 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-56" ]; then
		/etc/init.d/php-fpm-56 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-70" ]; then
		/etc/init.d/php-fpm-70 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-71" ]; then
		/etc/init.d/php-fpm-71 start > /dev/null 2>&1
	fi

	if [ -f "/etc/init.d/php-fpm-72" ]; then
		/etc/init.d/php-fpm-71 start > /dev/null 2>&1
	fi
	
	if [ -f "/etc/init.d/php-fpm-73" ]; then
		/etc/init.d/php-fpm-71 start > /dev/null 2>&1
	fi

	echo "True" > /www/server/panel/data/502Task.pl
}

while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Do you want to try to mount the data disk to the $setup_path directory?(y/n): " go;
done

if [ "$go" = 'n' ];then
	echo -e "Bye-bye"
	exit;
fi

if [ -f "/etc/init.d/bt" ] && [ -f "/www/server/panel/data/port.pl" ]; then
	disk=`cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`
	diskFree=`cat /proc/partitions |grep ${disk}|awk '{print $3}'`
	wwwUse=`du -sh -k /www|awk '{print $1}'`

	if [ "${diskFree}" -lt "${wwwUse}" ]; then
		echo -e "Sorry,your data disk is too small,can't coxpy to the www."
		echo -e "对不起，你的数据盘太小,无法迁移www目录数据到此数据盘"
		exit;
	else
		echo -e ""
		echo -e "stop bt-service"
		echo -e "停止宝塔服务"
		echo -e ""
		sleep 3
		stop_service
		echo -e ""
		mv /www /bt-backup
		echo -e "disk partition..."
		echo -e "磁盘分区..."
		sleep 2
		echo -e ""
		fdiskP
		echo -e ""
		echo -e "move disk..."
		echo -e "迁移数据中..."
		\cp -r -p -a /bt-backup/* /www
		echo -e ""
		echo -e "Done"
		echo -e "迁移完成"
		echo -e ""
		echo -e "start bt-service"
		echo -e "启动宝塔服务"
		echo -e ""
		start_service
	fi
else
	fdiskP
	echo -e ""
	echo -e "Done"
	echo -e "挂载成功"
fi

)
}

# ---------- Docker 一键安装配置（原 docker.sh 全部内容，子 shell 隔离） ----------
docker_install_main() {
(
# 使用 set -e 但允许关键步骤有错误处理
set -e
# 定义错误处理函数
handle_error() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo "❌ 命令执行失败，退出码: $exit_code"
    return $exit_code
  fi
  return 0
}

# ============================================================================
# 免责声明 / Disclaimer
# ============================================================================
# 本脚本为开源代码，仅供学习和参考使用。
# 使用本脚本前，请务必：
#   1. 在本地测试环境充分测试，确认脚本功能符合预期
#   2. 在生产环境使用前，备份重要数据和配置
#   3. 了解脚本执行的操作及其可能产生的影响
#
# 虽然脚本经过充分测试，但由于系统环境差异、网络状况等因素，
# 无法保证在所有环境下都能完美运行。使用本脚本所产生的任何后果，
# 包括但不限于数据丢失、服务中断等，均由使用者自行承担。
#
# This script is open source code, provided for learning and reference purposes only.
# Before using this script, please:
#   1. Fully test in a local test environment to ensure the script functions as expected
#   2. Backup important data and configurations before using in production environments
#   3. Understand the operations performed by the script and their potential impacts
#
# Although the script has been thoroughly tested, due to differences in system
# environments, network conditions, and other factors, we cannot guarantee
# perfect operation in all environments. Any consequences arising from the use
# of this script, including but not limited to data loss and service interruptions,
# shall be borne by the user.
# ============================================================================

# 检查是否安装了 sudo，如果没有则创建一个函数来模拟 sudo
if ! command -v sudo &> /dev/null; then
    echo "⚠️  未检测到 sudo 命令，将直接使用 root 权限执行命令"
    # 创建一个模拟 sudo 的函数
    sudo() {
        "$@"
    }
    export -f sudo
else
    echo "✅ 检测到 sudo 命令"
fi

# 恢复 /etc/docker/daemon.json 中与轩辕镜像相关的配置（需交互确认）
restore_docker_daemon_config() {
  local DETECTED_RESTORE_OS
  DETECTED_RESTORE_OS=$(uname -s 2>/dev/null || echo "Unknown")
  if [[ "$DETECTED_RESTORE_OS" == "Darwin" ]]; then
    echo ""
    echo "❌ macOS 不适用本脚本修改 Linux 路径下的 /etc/docker/daemon.json。"
    echo "💡 请在 Docker Desktop「设置 → Docker Engine」中编辑或重置配置。"
    return 1
  fi
  if [[ "$DETECTED_RESTORE_OS" == MINGW* ]] || [[ "$DETECTED_RESTORE_OS" == MSYS* ]] || [[ "$DETECTED_RESTORE_OS" == CYGWIN* ]]; then
    echo ""
    echo "❌ 当前为 Windows（Git Bash / MSYS / Cygwin 等），不适用本脚本的 Linux daemon.json 路径。"
    echo "💡 请在 Docker Desktop 中配置镜像；若在 WSL 内使用 Linux，请在 WSL 内运行本脚本。"
    return 1
  fi
  if ! [[ -t 0 ]]; then
    echo ""
    echo "❌ 恢复配置需在交互式终端中运行（未检测到 TTY），已跳过，未修改任何文件。"
    return 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 恢复 Docker 镜像相关配置"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 将修改 /etc/docker/daemon.json：可移除轩辕镜像加速、insecure-registries，"
  echo " 以及脚本曾写入的 dns 等。之后拉取镜像将更多依赖官方 registry（视网络而定）。"
  echo " 若选择「重置为默认 {}」，当前文件中的其它自定义项也会一并清空，请谨慎。"
  echo " 💡 确认时请完整输入 yes（不区分大小写，YES / Yes 均可）；其它输入视为取消。"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  local _confirm
  local _confirm_lower
  read -r -p "确认继续恢复？输入 yes 继续，其它任意键取消: " _confirm
  _confirm_lower=$(printf '%s' "$_confirm" | tr '[:upper:]' '[:lower:]')
  if [[ "$_confirm_lower" != "yes" ]]; then
    echo "ℹ️  已取消，未修改任何文件。"
    return 0
  fi

  echo ""
  echo "请选择恢复方式："
  echo " 1) 从最新一份 daemon.json.backup.* 恢复（排除 before_restore 备份）"
  echo " 2) 重置为 Docker 默认（写入空对象 {}，不依赖备份）"
  local sub
  while true; do
    read -r -p "请输入 [1/2]: " sub
    if [[ "$sub" == "1" || "$sub" == "2" ]]; then
      break
    fi
    echo "❌ 无效选择，请输入 1 或 2"
  done

  sudo mkdir -p /etc/docker

  if [[ "$sub" == "1" ]]; then
    local latest=""
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" == *before_restore* ]] && continue
      latest="$line"
      break
    done < <(ls -1t /etc/docker/daemon.json.backup.* 2>/dev/null || true)
    if [[ -z "$latest" ]] || [[ ! -f "$latest" ]]; then
      echo ""
      echo "❌ 未找到可用的 daemon.json.backup.*（不含 before_restore），无法从历史备份还原。"
      echo "💡 请重新运行本功能并选择 2) 重置为 {}，或手动编辑 /etc/docker/daemon.json。"
      return 1
    fi
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    if [[ -f /etc/docker/daemon.json ]]; then
      sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.before_restore.$ts"
      echo "✅ 已备份当前配置到 /etc/docker/daemon.json.backup.before_restore.$ts"
    fi
    sudo cp "$latest" /etc/docker/daemon.json
    echo "✅ 已从备份恢复: $latest"
  else
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    if [[ -f /etc/docker/daemon.json ]]; then
      sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.before_restore.$ts"
      echo "✅ 已备份当前配置到 /etc/docker/daemon.json.backup.before_restore.$ts"
    fi
    local _y
    read -r -p "确认将 /etc/docker/daemon.json 重置为 {}？[y/N]: " _y
    if [[ ! "$_y" =~ ^[Yy]$ ]]; then
      echo "ℹ️  已取消重置（若已生成 before_restore 备份，可自行保留或删除）。"
      return 0
    fi
    echo '{}' | sudo tee /etc/docker/daemon.json > /dev/null
    echo "✅ 已重置为 {}"
  fi

  local SCRIPT_RESTORE_SYSTEMD_OK=false
  if command -v systemctl &>/dev/null; then
    local PID1_COMM_RESTORE
    PID1_COMM_RESTORE=$(tr -d '\0' < /proc/1/comm 2>/dev/null || echo "")
    if [[ "$PID1_COMM_RESTORE" == "systemd" ]] && systemctl show-environment &>/dev/null 2>&1; then
      SCRIPT_RESTORE_SYSTEMD_OK=true
    fi
  fi
  if [[ "$SCRIPT_RESTORE_SYSTEMD_OK" == "true" ]]; then
    sudo systemctl daemon-reexec || true
    sudo systemctl restart docker || true
    echo "✅ 已尝试重载 Docker 服务"
  else
    echo "ℹ️  未检测到可用 systemd，请手动执行: sudo systemctl restart docker（或按需启动 dockerd）"
  fi
  echo ""
  echo "💡 可通过 docker info 查看 Registry Mirrors 是否已变更。"
  return 0
}

echo "=========================================="
echo "🐳 欢迎使用轩辕镜像 Docker 一键安装配置脚本"
echo "=========================================="
echo "官方网站: https://xuanyuan.cloud/"
echo ""
echo "请选择操作模式："
echo "1) 一键安装配置（推荐）"
echo "2) 修改轩辕镜像专属域名"
echo "3) 恢复 Docker 镜像相关配置"
echo ""
# 循环等待用户输入有效选择
while true; do
    read -p "请输入选择 [1/2/3]: " mode_choice
    
    if [[ "$mode_choice" == "1" ]]; then
        echo ""
        echo ">>> 模式：一键安装配置"
        
        # 检查是否已经安装了 Docker
        if command -v docker &> /dev/null; then
            DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
            echo ""
            echo "⚠️  检测到系统已安装 Docker 版本: $DOCKER_VERSION"
            echo ""
            echo "⚠️  重要提示："
            echo "   选择此选项将进行 Docker 升级或重装操作"
            echo "   这可能会影响现有的 Docker 容器和数据"
            echo "   建议在操作前备份重要的容器和数据"
            echo ""
            echo "请确认是否继续："
            echo "1) 确认继续安装/升级 Docker"
            echo "2) 返回选择菜单"
            echo ""
            
            # 循环等待用户输入有效选择
            while true; do
                read -p "请输入选择 [1/2]: " confirm_choice
                
                if [[ "$confirm_choice" == "1" ]]; then
                    echo ""
                    echo "✅ 用户确认继续，将进行 Docker 安装/升级..."
                    echo ""
                    break
                elif [[ "$confirm_choice" == "2" ]]; then
                    echo ""
                    echo "🔄 返回选择菜单..."
                    echo ""
                    # 重新显示菜单选项
                    echo "请选择操作模式："
                    echo "1) 一键安装配置（推荐）"
                    echo "2) 修改轩辕镜像专属域名"
                    echo "3) 恢复 Docker 镜像相关配置"
                    echo ""
                    # 重置 mode_choice 以重新进入循环
                    mode_choice=""
                    break
                else
                    echo "❌ 无效选择，请输入 1 或 2"
                    echo ""
                fi
            done
            
            # 如果用户选择了返回菜单，继续外层循环
            if [[ "$confirm_choice" == "2" ]]; then
                continue
            fi
        fi
        
        echo ""
        break
    elif [[ "$mode_choice" == "2" ]]; then
        echo ""
        echo ">>> 模式：仅修改镜像地址"
        echo ""
        
        # 检查 Docker 是否已安装
        if ! command -v docker &> /dev/null; then
            echo "❌ 检测到 Docker 未安装！"
            echo ""
            echo "⚠️  风险提示："
            echo "   - 无法验证镜像配置是否生效"
            echo "   - 可能导致后续 Docker 操作失败"
            echo "   - 建议先完成 Docker 安装"
            echo ""
            echo "💡 建议：选择选项 1 进行一键安装配置"
            echo ""
            echo "已退出脚本，请重新运行并选择选项 1 进行完整安装配置"
            exit 1
        else
            # 检查 Docker 版本
            DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
            MAJOR_VERSION=$(echo $DOCKER_VERSION | cut -d. -f1)
            
            if [[ "$MAJOR_VERSION" -lt 20 ]]; then
                echo "⚠️  检测到 Docker 版本 $DOCKER_VERSION 低于 20.0"
                echo ""
                echo "⚠️  风险提示："
                echo "   - 低版本 Docker 可能存在安全漏洞"
                echo "   - 某些新功能可能不可用"
                echo "   - 建议升级到 Docker 20+ 版本"
                echo ""
                echo "💡 建议：选择选项 1 进行一键安装配置和升级"
                echo ""
                read -p "是否仍要继续？[y/N]: " continue_choice
                if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                    echo "已取消操作，建议选择选项 1 进行完整安装配置"
                    exit 0
                fi
            fi
        fi
        
        echo ""
        echo ">>> 配置轩辕镜像地址"
        echo ""
        echo "请选择版本："
        echo "1) 轩辕镜像免费版 (域名: docker.xuanyuan.me)"
        echo "2) 轩辕镜像专业版 (专属域名 *.xuanyuan.run / *.xuanyuan.dev ，不含免费版域名)"
        echo "3) 恢复/重置镜像相关配置"
        # 循环等待用户输入有效选择
        while true; do
            read -p "请输入选择 [1/2/3]: " choice
            if [[ "$choice" == "1" || "$choice" == "2" ]]; then
                break
            elif [[ "$choice" == "3" ]]; then
                restore_docker_daemon_config
                exit $?
            else
                echo "❌ 无效选择，请输入 1、2 或 3"
                echo ""
            fi
        done
        
        mirror_list=""
        
        if [[ "$choice" == "2" ]]; then
            read -p "请输入您的轩辕镜像专属域名 (访问官网获取：https://xuanyuan.cloud): " custom_domain
            
            # 清理用户输入的域名，移除协议前缀
            custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
            
            # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
            if [[ "$custom_domain" == *.xuanyuan.run ]]; then
                custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
                mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_dev"
]
EOF
)
            elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
                custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
                mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_run"
]
EOF
)
            else
                mirror_list=$(cat <<EOF
[
  "https://$custom_domain"
]
EOF
)
            fi
        else
            mirror_list=$(cat <<EOF
[
  "https://docker.xuanyuan.me"
]
EOF
)
        fi
        
        # 创建 Docker 配置目录
        mkdir -p /etc/docker
        
        # 备份现有配置
        if [ -f /etc/docker/daemon.json ]; then
            sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
            echo "✅ 已备份现有配置到 /etc/docker/daemon.json.backup.*"
        fi
        
        # 写入新配置
        
        # 根据用户选择设置 insecure-registries
        if [[ "$choice" == "2" ]]; then
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_run"
]
EOF
)
          else
            insecure_registries=$(cat <<EOF
[
  "$custom_domain"
]
EOF
)
          fi
        else
          insecure_registries=$(cat <<EOF
[
  "docker.xuanyuan.me"
]
EOF
)
        fi

        cat <<EOF | tee /etc/docker/daemon.json
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries
}
EOF

# 如果没有禁用 DNS 配置且宿主机没有配置 DNS，则添加 DNS 配置
if [[ "$SKIP_DNS" != "true" ]]; then
  if grep -q "nameserver" /etc/resolv.conf; then
    echo "ℹ️  检测到系统已配置 DNS，跳过 Docker DNS 配置以避免冲突"
  else
    # 使用 jq 或 python 来修改 json 文件，避免直接覆盖
    if command -v jq &> /dev/null; then
      tmp_json=$(mktemp)
      sudo jq '. + {"dns": ["119.29.29.29", "114.114.114.114"]}' /etc/docker/daemon.json > "$tmp_json" && sudo mv "$tmp_json" /etc/docker/daemon.json
      echo "✅ 已添加 Docker DNS 配置"
    else
      # 简单的 sed 替换作为后备方案
      sudo sed -i 's/}/,\n  "dns": ["119.29.29.29", "114.114.114.114"]\n}/' /etc/docker/daemon.json
      echo "✅ 已添加 Docker DNS 配置"
    fi
  fi
fi
        
        echo "✅ 镜像配置已更新"
        echo ""
        echo "当前配置的镜像源："
        if [[ "$choice" == "2" ]]; then
            if [[ "$custom_domain" == *.xuanyuan.run ]]; then
                custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_dev (备用)"
            elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
                custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_run (备用)"
            else
                echo "  - https://$custom_domain"
            fi
        else
            echo "  - https://docker.xuanyuan.me"
        fi
        echo ""
        
        # 如果 Docker 服务正在运行，重启以应用配置
        if systemctl is-active --quiet docker 2>/dev/null; then
            echo "正在重启 Docker 服务以应用新配置..."
            systemctl daemon-reexec || true
            systemctl restart docker || true
            
            # 等待服务启动
            sleep 3
            
            if systemctl is-active --quiet docker; then
                echo "✅ Docker 服务重启成功，新配置已生效"
            else
                echo "❌ Docker 服务重启失败，请手动重启"
            fi
        else
            echo "⚠️  Docker 服务未运行，配置将在下次启动时生效"
        fi
        
        echo ""
        echo "🎉 镜像配置完成！"
        exit 0
    elif [[ "$mode_choice" == "3" ]]; then
        echo ""
        echo ">>> 模式：恢复 Docker 镜像相关配置"
        restore_docker_daemon_config
        exit $?
    else
        echo "❌ 无效选择，请输入 1、2 或 3"
        echo ""
    fi
done

# 检测 macOS 和 Windows 系统
DETECTED_OS=$(uname -s 2>/dev/null || echo "Unknown")

# macOS 检测
if [[ "$DETECTED_OS" == "Darwin" ]]; then
  echo "🍎 检测到 macOS 系统"
  echo ""
  echo "=========================================="
  echo "⚠️  macOS 不支持此 Linux 安装脚本"
  echo "=========================================="
  echo ""
  echo "📋 macOS 安装 Docker 的正确方式："
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "方法一：使用 Homebrew 安装（推荐）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. 如果未安装 Homebrew，先安装："
  echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo ""
  echo "  2. 使用 Homebrew 安装 Docker Desktop："
  echo "     brew install --cask docker"
  echo ""
  echo "  3. 启动 Docker Desktop："
  echo "     打开「应用程序」文件夹，双击 Docker 图标"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "方法二：下载官方安装包"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  访问：https://www.docker.com/products/docker-desktop"
  echo "  下载 Docker Desktop for Mac (Apple Silicon 或 Intel)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 配置轩辕镜像"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. 启动 Docker Desktop"
  echo "  2. 点击菜单栏 Docker 图标 → Settings (设置)"
  echo "  3. 选择 Docker Engine"
  echo "  4. 在 JSON 配置中添加："
  echo ""
  echo '  {'
  echo '    "registry-mirrors": ['
  echo '      "https://docker.xuanyuan.me"'
  echo '    ],'
  echo '    "insecure-registries": ['
  echo '      "docker.xuanyuan.me"'
  echo '    ]'
  echo '  }'
  echo ""
  echo "  5. 点击 Apply & Restart（应用并重启）"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📚 更多信息"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  官方网站：https://xuanyuan.cloud/"
  echo "  Docker 文档：https://docs.docker.com/desktop/install/mac-install/"
  echo ""
  echo "=========================================="
  exit 0
fi

# Windows 检测（Git Bash、WSL、Cygwin、MSYS2 等）
if [[ "$DETECTED_OS" == MINGW* ]] || [[ "$DETECTED_OS" == MSYS* ]] || [[ "$DETECTED_OS" == CYGWIN* ]]; then
  echo "🪟 检测到 Windows 系统"
  echo ""
  echo "=========================================="
  echo "⚠️  Windows 不支持此 Linux 安装脚本"
  echo "=========================================="
  echo ""
  echo "📋 Windows 安装 Docker 的正确方式："
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "方法一：Docker Desktop（推荐）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. 访问官方网站："
  echo "     https://www.docker.com/products/docker-desktop"
  echo ""
  echo "  2. 下载 Docker Desktop for Windows"
  echo ""
  echo "  3. 运行安装程序并按提示完成安装"
  echo ""
  echo "  4. 重启计算机（如果需要）"
  echo ""
  echo "  📌 系统要求："
  echo "     - Windows 10/11 64位专业版、企业版或教育版"
  echo "     - 启用 WSL 2（Windows Subsystem for Linux 2）"
  echo "     - 启用 Hyper-V 和容器功能"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "方法二：在 WSL 2 中使用（高级用户）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. 安装 WSL 2："
  echo "     wsl --install"
  echo ""
  echo "  2. 安装 Ubuntu 或其他 Linux 发行版"
  echo ""
  echo "  3. 在 WSL 2 中运行本安装脚本："
  echo "     bash <(curl -fsSL https://xuanyuan.cloud/docker.sh)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 配置轩辕镜像"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. 启动 Docker Desktop"
  echo "  2. 点击系统托盘 Docker 图标 → Settings (设置)"
  echo "  3. 选择 Docker Engine"
  echo "  4. 在 JSON 配置中添加："
  echo ""
  echo '  {'
  echo '    "registry-mirrors": ['
  echo '      "https://docker.xuanyuan.me"'
  echo '    ],'
  echo '    "insecure-registries": ['
  echo '      "docker.xuanyuan.me"'
  echo '    ]'
  echo '  }'
  echo ""
  echo "  5. 点击 Apply & Restart（应用并重启）"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📚 更多信息"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  官方网站：https://xuanyuan.cloud/"
  echo "  Docker 文档：https://docs.docker.com/desktop/install/windows-install/"
  echo "  WSL 2 安装：https://docs.microsoft.com/windows/wsl/install"
  echo ""
  echo "=========================================="
  exit 0
fi

echo ">>> [1/8] 检查系统信息..."
OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)
VERSION_ID=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
echo "系统: $OS $VERSION_ID 架构: $ARCH"

# 映射架构标识到 Docker 官方使用的架构名称
case "$ARCH" in
  x86_64)
    DOCKER_ARCH="x86_64"
    echo "✅ 检测到 x86_64 架构（Intel/AMD 64位）"
    ;;
  aarch64|arm64)
    DOCKER_ARCH="aarch64"
    echo "✅ 检测到 ARM 64位架构（aarch64），支持鲲鹏、飞腾等处理器"
    ;;
  armv7l|armhf)
    DOCKER_ARCH="armhf"
    echo "✅ 检测到 ARM 32位硬浮点架构（armhf）"
    ;;
  armv6l|armel)
    DOCKER_ARCH="armel"
    echo "✅ 检测到 ARM 32位软浮点架构（armel）"
    ;;
  s390x)
    DOCKER_ARCH="s390x"
    echo "✅ 检测到 IBM Z 架构（s390x）"
    ;;
  ppc64le)
    DOCKER_ARCH="ppc64le"
    echo "✅ 检测到 PowerPC 64位小端架构（ppc64le）"
    ;;
  *)
    echo "⚠️  检测到架构: $ARCH"
    echo "⚠️  Docker 官方静态二进制包可能不支持此架构"
    echo "⚠️  将尝试使用 $ARCH 作为架构标识，如果下载失败请手动安装"
    DOCKER_ARCH="$ARCH"
    ;;
esac
echo "📦 Docker 将使用架构标识: $DOCKER_ARCH"

# 针对 Debian 10 和 Ubuntu 16.04 显示特殊提示
if [[ "$OS" == "debian" && "$VERSION_ID" == "10" ]]; then
  echo ""
  echo "⚠️  检测到 Debian 10 (Buster) 系统"
  echo "📋 系统状态说明："
  echo "   - Debian 10 已于 2022 年 8 月结束生命周期"
  echo "   - 官方软件源已迁移到 archive.debian.org"
  echo "   - 本脚本将自动配置国内镜像源以提高下载速度"
  echo "   - 建议考虑升级到 Debian 11+ 或 Ubuntu 20.04+"
  echo ""
  echo "🚀 优化措施："
  echo "   - 使用阿里云/腾讯云/华为云镜像源"
  echo "   - 自动检测并切换可用的镜像源"
  echo "   - 使用二进制安装方式避免包依赖问题"
  echo ""
elif [[ "$OS" == "ubuntu" && "$VERSION_ID" == "16.04" ]]; then
  echo ""
  echo "⚠️  检测到 Ubuntu 16.04 (Xenial) 系统"
  echo "📋 系统状态说明："
  echo "   - Ubuntu 16.04 已于 2021 年 4 月结束标准支持"
  echo "   - Docker 官方仓库缺少部分新组件（如 docker-buildx-plugin）"
  echo "   - 本脚本将使用二进制安装方式以确保兼容性"
  echo "   - 强烈建议升级到 Ubuntu 20.04 LTS 或 Ubuntu 22.04 LTS"
  echo ""
  echo "🚀 优化措施："
  echo "   - 使用 Docker 二进制包直接安装"
  echo "   - 自动配置多个国内镜像源"
  echo "   - 跳过不兼容的组件安装"
  echo ""
elif [[ "$OS" == "centos" && "$VERSION_ID" == "7" ]]; then
  echo ""
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo "⚠️  重要提醒：CentOS 7 生命周期已结束"
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo "⚠️  📅 2024 年 6 月 30 日：CentOS 7 结束生命周期（EOL）"
  echo "⚠️  "
  echo "⚠️  之后，不再接收官方更新或安全补丁"
  echo "⚠️  建议升级到受支持的操作系统版本"
  echo "⚠️  "
  echo "⚠️  推荐替代方案："
  echo "⚠️    - Rocky Linux 8/9（CentOS 的社区替代品）"
  echo "⚠️    - AlmaLinux 8/9（企业级长期支持）"
  echo "⚠️    - CentOS Stream 8/9（滚动发布版本）"
  echo "⚠️    - Red Hat Enterprise Linux 8/9（商业支持）"
  echo "⚠️  "
  echo "⚠️  当前将使用归档源继续安装，但强烈建议尽快升级系统"
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo ""
elif [[ "$OS" == "centos" && "$VERSION_ID" == "8" ]]; then
  echo ""
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo "⚠️  重要提醒：CentOS 8 生命周期已结束"
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo "⚠️  📅 2021 年 12 月 31 日：CentOS 8 结束生命周期（EOL）"
  echo "⚠️  "
  echo "⚠️  之后，不再接收官方更新或安全补丁"
  echo "⚠️  建议升级到受支持的操作系统版本"
  echo "⚠️  "
  echo "⚠️  推荐替代方案："
  echo "⚠️    - Rocky Linux 8/9（CentOS 的社区替代品）"
  echo "⚠️    - AlmaLinux 8/9（企业级长期支持）"
  echo "⚠️    - CentOS Stream 8/9（滚动发布版本）"
  echo "⚠️    - Red Hat Enterprise Linux 8/9（商业支持）"
  echo "⚠️  "
  echo "⚠️  当前将使用归档源继续安装，但强烈建议尽快升级系统"
  echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
  echo ""
elif [[ "$OS" == "kylin" || "$OS" == "uos" || "$OS" == "uniontechos" ]]; then
  echo ""
  if [[ "$OS" == "kylin" ]]; then
    # 规范显示银河麒麟版本，避免出现 Vv10 等重复前缀
    if [[ "$VERSION_ID" =~ ^[Vv] ]]; then
      KYLIN_VERSION_DISPLAY="$VERSION_ID"
    else
      KYLIN_VERSION_DISPLAY="V$VERSION_ID"
    fi
    echo "✅ 检测到银河麒麟操作系统 (Kylin Linux) $KYLIN_VERSION_DISPLAY"
    echo "📋 系统信息："
    echo "   - Kylin Linux 基于 RHEL，与 CentOS/RHEL 兼容"
    echo "   - 使用 yum/dnf 包管理器"
    echo "   - 支持国内镜像"
  else
    echo "✅ 检测到统信操作系统 (UnionTechOS / UOS) $VERSION_ID"
    echo "📋 系统信息："
    echo "   - 与 RHEL/CentOS 软件生态兼容，使用 yum/dnf 包管理器"
    echo "   - Docker CE 将按兼容映射使用国内 CentOS 系镜像源"
    echo "   - 支持国内镜像"
  fi
  echo ""
elif [[ "$OS" == "kali" ]]; then
  echo ""
  echo "✅ 检测到 Kali Linux $VERSION_ID"
  echo "📋 系统信息："
  echo "   - Kali Linux 基于 Debian，与 Debian 完全兼容"
  echo "   - 使用 apt 包管理器"
  echo "   - 将使用 Debian 兼容的安装方法"
  echo "   - 支持国内镜像"
  echo ""
elif [[ "$OS" == "deepin" ]]; then
  echo ""
  echo "✅ 检测到深度操作系统 (Deepin) $VERSION_ID"
  echo "📋 系统信息："
  echo "   - Deepin 基于 Debian，使用 apt 包管理器"
  echo "   - Docker CE 使用官方 linux/debian 源（Deepin 代号将映射为 Debian suite）"
  echo "   - 支持国内镜像"
  echo ""
fi

echo ">>> [1.5/8] 检查 Docker 安装状态..."
if command -v docker &> /dev/null; then
    echo "检测到 Docker 已安装"
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    echo "当前 Docker 版本: $DOCKER_VERSION"
    
    # 提取主版本号进行比较
    MAJOR_VERSION=$(echo $DOCKER_VERSION | cut -d. -f1)
    
    if [[ "$MAJOR_VERSION" -lt 20 ]]; then
        echo "警告: 当前 Docker 版本 $DOCKER_VERSION 低于 20.0"
        echo "建议升级到 Docker 20+ 版本以获得更好的性能和功能"
        read -p "是否要升级 Docker? [y/N]: " upgrade_choice
        
        if [[ "$upgrade_choice" =~ ^[Yy]$ ]]; then
            echo "用户选择升级 Docker，继续执行安装流程..."
        else
            echo "用户选择不升级，跳过 Docker 安装"
                    echo ">>> [5/8] 配置轩辕镜像..."
        
        # 循环等待用户选择镜像版本
        while true; do
            echo "请选择版本:"
            echo "1) 轩辕镜像免费版 (域名: docker.xuanyuan.me)"
            echo "2) 轩辕镜像专业版 (专属域名: *.xuanyuan.run / *.xuanyuan.dev 不含免费版域名)"
            echo "3) 恢复/重置镜像相关配置"
            read -p "请输入选择 [1/2/3]: " choice
            
            if [[ "$choice" == "1" || "$choice" == "2" ]]; then
                break
            elif [[ "$choice" == "3" ]]; then
                restore_docker_daemon_config
                exit $?
            else
                echo "❌ 无效选择，请输入 1、2 或 3"
                echo ""
            fi
        done
        
        mirror_list=""
        
        if [[ "$choice" == "2" ]]; then
          read -p "请输入您的轩辕镜像专属域名 (访问官网获取：https://xuanyuan.cloud): " custom_domain
          
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_run"
]
EOF
)
          else
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain"
]
EOF
)
          fi
        else
          mirror_list=$(cat <<EOF
[
  "https://docker.xuanyuan.me"
]
EOF
)
        fi
        
        sudo mkdir -p /etc/docker

        # 根据用户选择设置 insecure-registries
        if [[ "$choice" == "2" ]]; then
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_run"
]
EOF
)
          else
            insecure_registries=$(cat <<EOF
[
  "$custom_domain"
]
EOF
)
          fi
        else
          insecure_registries=$(cat <<EOF
[
  "docker.xuanyuan.me"
]
EOF
)
        fi

        # 准备 DNS 配置字符串
dns_config=""
if [[ "$SKIP_DNS" != "true" ]]; then
  if ! grep -q "nameserver" /etc/resolv.conf; then
     dns_config=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
  else
     echo "ℹ️  检测到系统已配置 DNS，跳过 Docker DNS 配置以避免冲突"
  fi
fi

cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_config
}
EOF
        
        sudo systemctl daemon-reexec || true
        sudo systemctl restart docker || true
        
        echo ">>> [6/8] 安装完成！"
        echo "🎉Docker 镜像已配置完成"
        echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
        echo "官方网站: https://xuanyuan.cloud/"
        
        # 显示当前配置的镜像源
        echo ""
        echo "当前配置的镜像源："
        if [[ "$choice" == "2" ]]; then
            if [[ "$custom_domain" == *.xuanyuan.run ]]; then
                custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_dev (备用)"
            elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
                custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_run (备用)"
            else
                echo "  - https://$custom_domain"
            fi
        else
            echo "  - https://docker.xuanyuan.me"
        fi
        echo ""
        
        # 继续执行完整的流程，不在这里退出
        fi
    else
        echo "Docker 版本 $DOCKER_VERSION 满足要求 (>= 20.0)"
        echo "跳过 Docker 安装，直接配置镜像..."
        
        echo ">>> [5/8] 配置国内镜像..."
        
        # 循环等待用户选择镜像版本
        while true; do
            echo "请选择版本:"
            echo "1) 轩辕镜像免费版 (域名: docker.xuanyuan.me)"
            echo "2) 轩辕镜像专业版 (专属域名 *.xuanyuan.run / *.xuanyuan.dev 不含免费版域名)"
            echo "3) 恢复/重置镜像相关配置"
            read -p "请输入选择 [1/2/3]: " choice
            
            if [[ "$choice" == "1" || "$choice" == "2" ]]; then
                break
            elif [[ "$choice" == "3" ]]; then
                restore_docker_daemon_config
                exit $?
            else
                echo "❌ 无效选择，请输入 1、2 或 3"
                echo ""
            fi
        done
        
        mirror_list=""
        
        if [[ "$choice" == "2" ]]; then
          read -p "请输入您的轩辕镜像专属域名 (访问官网获取：https://xuanyuan.cloud): " custom_domain

          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_run"
]
EOF
)
          else
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain"
]
EOF
)
          fi
        else
          mirror_list=$(cat <<EOF
[
  "https://docker.xuanyuan.me"
]
EOF
)
        fi
        
        sudo mkdir -p /etc/docker

        # 根据用户选择设置 insecure-registries
        if [[ "$choice" == "2" ]]; then
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_run"
]
EOF
)
          else
            insecure_registries=$(cat <<EOF
[
  "$custom_domain"
]
EOF
)
          fi
        else
          insecure_registries=$(cat <<EOF
[
  "docker.xuanyuan.me"
]
EOF
)
        fi

        # 准备 DNS 配置字符串
dns_config=""
if [[ "$SKIP_DNS" != "true" ]]; then
  if ! grep -q "nameserver" /etc/resolv.conf; then
     dns_config=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
  else
     echo "ℹ️  检测到系统已配置 DNS，跳过 Docker DNS 配置以避免冲突"
  fi
fi

cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_config
}
EOF
        
        sudo systemctl daemon-reexec || true
        sudo systemctl restart docker || true
        
        echo ">>> [6/8] 安装完成！"
        echo "🎉Docker 镜像已配置完成"
        echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
        echo "官方网站: https://xuanyuan.cloud/"
        exit 0
    fi
else
    echo "未检测到 Docker，将进行全新安装"
fi

echo ">>> [2/8] 配置国内 Docker 源..."
# 将 OS 转换为小写进行比较（支持 openEuler、openeuler 等大小写形式）
OS_LOWER=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
if [[ "$OS_LOWER" == "openeuler" ]]; then
  # openEuler (欧拉操作系统) 支持
  echo "检测到 openEuler (欧拉操作系统) $VERSION_ID"
  
  # 判断使用 dnf 还是 yum
  if [[ "${VERSION_ID%%.*}" -ge 22 ]]; then
    # openEuler 22+ 使用 dnf
    PKG_MANAGER="dnf"
    CENTOS_VERSION="9"
    echo "使用 dnf 包管理器 (openEuler $VERSION_ID 使用 CentOS 9 兼容源)"
  elif [[ "${VERSION_ID%%.*}" -ge 20 ]]; then
    # openEuler 20-21 使用 dnf，基于 CentOS 8
    PKG_MANAGER="dnf"
    CENTOS_VERSION="8"
    echo "使用 dnf 包管理器 (openEuler $VERSION_ID 使用 CentOS 8 兼容源)"
  else
    # openEuler 旧版本使用 yum，基于 CentOS 7
    PKG_MANAGER="yum"
    CENTOS_VERSION="7"
    echo "使用 yum 包管理器 (openEuler $VERSION_ID 使用 CentOS 7 兼容源)"
  fi
  
  sudo $PKG_MANAGER install -y ${PKG_MANAGER}-utils
  
  # 定义切换 Docker 镜像源的函数
  switch_docker_mirror() {
    local mirror_index=$1
    local centos_version=${CENTOS_VERSION:-9}
    local repo_added=false
    
    case $mirror_index in
      1)
        echo "尝试配置阿里云 Docker 源..."
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${centos_version}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
        ;;
      2)
        echo "尝试配置腾讯云 Docker 源..."
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${centos_version}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
        ;;
      3)
        echo "尝试配置中科大 Docker 源..."
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${centos_version}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
        ;;
      4)
        echo "尝试配置清华大学 Docker 源..."
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${centos_version}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
        ;;
      5)
        echo "尝试配置官方 Docker 源..."
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${centos_version}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
        ;;
      *)
        return 1
        ;;
    esac
    
    # 清理缓存并更新
    sudo $PKG_MANAGER clean all 2>/dev/null || true
    sudo rm -rf /var/cache/dnf/* 2>/dev/null || true
    sudo rm -rf /var/cache/yum/* 2>/dev/null || true
    
    if sudo $PKG_MANAGER makecache; then
      repo_added=true
      echo "✅ Docker 源切换成功"
      return 0
    else
      echo "❌ Docker 源切换失败"
      return 1
    fi
  }
  
  # 尝试多个国内镜像源（优先华为云，因为 openEuler 是华为开发）
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  CURRENT_MIRROR_INDEX=0  # 0=华为云, 1=阿里云, 2=腾讯云, 3=中科大, 4=清华, 5=官方
  
  # 创建Docker仓库配置文件，使用 openEuler 兼容的 CentOS 版本
  echo "正在创建 Docker 仓库配置 (使用 CentOS ${CENTOS_VERSION} 兼容源)..."
  
  # 源1: 华为云镜像（openEuler 是华为开发，优先使用华为云）
  echo "尝试配置华为云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo $PKG_MANAGER makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 华为云 Docker 源配置成功"
  else
    echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 阿里云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置阿里云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 阿里云 Docker 源配置成功"
    else
      echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 检查是否安装了 iSulad（openEuler 的容器运行时，与 Docker 冲突）
  if rpm -q iSulad &>/dev/null; then
    echo "⚠️  检测到系统已安装 iSulad（openEuler 容器运行时）"
    echo "⚠️  iSulad 与 Docker CE 存在包冲突，需要卸载 iSulad 才能安装 Docker"
    echo "正在卸载 iSulad..."
    if sudo $PKG_MANAGER remove -y iSulad 2>/dev/null; then
      echo "✅ iSulad 卸载成功"
    else
      echo "⚠️  iSulad 卸载失败，将使用 --allowerasing 参数处理冲突"
    fi
  fi
  
  # 在安装 docker-ce 之前，先检查并安装 libnftables 依赖
  echo ">>> [3.1/8] 检查 libnftables 依赖..."
  if ! rpm -q libnftables >/dev/null 2>&1; then
    echo "⚠️  未检测到 libnftables，正在安装..."
    if sudo $PKG_MANAGER install -y libnftables 2>&1; then
      echo "✅ libnftables 安装成功"
    else
      echo "⚠️  libnftables 安装失败，将在安装 docker-ce 时重试"
    fi
  else
    echo "✅ libnftables 已安装"
  fi
  
  # 尝试安装 Docker，使用 --allowerasing 参数处理 runc 冲突
  # containerd.io 会替代系统的 runc，需要使用 --allowerasing 允许替换
  if sudo $PKG_MANAGER install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin; then
    echo "✅ Docker CE 安装成功"
  else
    echo "❌ 批量安装失败，尝试逐个安装组件（使用 --allowerasing）..."
    
    # 再次检查 libnftables（批量安装失败后）
    echo "再次检查 libnftables 依赖..."
    if ! rpm -q libnftables >/dev/null 2>&1; then
      echo "⚠️  未检测到 libnftables，正在安装..."
      if sudo $PKG_MANAGER install -y libnftables 2>&1; then
        echo "✅ libnftables 安装成功"
      else
        echo "⚠️  libnftables 安装失败"
      fi
    else
      echo "✅ libnftables 已安装"
    fi
    
    # 逐个安装组件，都使用 --allowerasing 处理冲突
    CONTAINERD_INSTALLED=false
    CONTAINERD_OUTPUT=""
    if sudo $PKG_MANAGER install -y --allowerasing containerd.io 2>&1; then
      echo "✅ containerd.io 安装成功"
      CONTAINERD_INSTALLED=true
    else
      CONTAINERD_OUTPUT=$(sudo $PKG_MANAGER install -y --allowerasing containerd.io 2>&1 || true)
      echo "❌ containerd.io 安装失败"
      
      # 检测是否是校验和错误，如果是则尝试切换镜像源
      if echo "$CONTAINERD_OUTPUT" | grep -qiE "(checksum doesn't match|校验和不匹配|Cannot download|all mirrors were already tried)"; then
        echo "⚠️  检测到下载失败或校验和不匹配，尝试切换 Docker 镜像源..."
        
        # 尝试切换其他镜像源（从阿里云开始，因为华为云已经失败）
        for mirror_idx in 1 2 3 4 5; do
          if switch_docker_mirror $mirror_idx; then
            CURRENT_MIRROR_INDEX=$mirror_idx
            echo "  - 重新尝试安装 containerd.io..."
            if sudo $PKG_MANAGER install -y --allowerasing containerd.io 2>&1; then
              echo "✅ containerd.io 安装成功（切换镜像源后）"
              CONTAINERD_INSTALLED=true
              break
            else
              echo "  ❌ 切换镜像源后仍然失败，尝试下一个镜像源..."
            fi
          fi
        done
        
        if [[ "$CONTAINERD_INSTALLED" == "false" ]]; then
          echo "❌ 所有镜像源都尝试失败，containerd.io 无法安装"
        fi
      fi
    fi
    
    if sudo $PKG_MANAGER install -y --allowerasing docker-ce-cli; then
      echo "✅ docker-ce-cli 安装成功"
    else
      echo "❌ docker-ce-cli 安装失败"
    fi
    
    DOCKER_CE_INSTALLED=false
    DOCKER_CE_OUTPUT=""
    # 使用临时变量捕获退出码，因为 tee 会改变退出码
    DOCKER_CE_INSTALL_LOG=$(sudo $PKG_MANAGER install -y --allowerasing docker-ce 2>&1 | tee /tmp/docker-ce-install.log)
    DOCKER_CE_INSTALL_STATUS=${PIPESTATUS[0]}
    
    if [[ $DOCKER_CE_INSTALL_STATUS -eq 0 ]]; then
      # 再次验证 docker-ce 是否真的安装成功
      if rpm -q docker-ce >/dev/null 2>&1; then
        echo "✅ docker-ce 安装成功"
        DOCKER_CE_INSTALLED=true
      else
        echo "⚠️  安装命令成功但 docker-ce 包未找到，可能安装失败"
        DOCKER_CE_OUTPUT="$DOCKER_CE_INSTALL_LOG"
        echo "❌ docker-ce 安装失败"
      fi
    else
      DOCKER_CE_OUTPUT="$DOCKER_CE_INSTALL_LOG"
      echo "❌ docker-ce 安装失败"
      
      # 检测是否是 libnftables 依赖问题
      if echo "$DOCKER_CE_OUTPUT" | grep -qiE "libnftables|LIBNFTABLES"; then
        echo "⚠️  检测到 libnftables 依赖问题"
        
        # 先检查 libnftables 是否已安装
        if rpm -q libnftables >/dev/null 2>&1; then
          echo "⚠️  libnftables 已安装，但版本可能不兼容，尝试升级..."
          sudo $PKG_MANAGER update -y libnftables 2>&1 || true
        else
          echo "正在尝试安装 libnftables 依赖..."
        fi
        
        # 尝试安装 libnftables（显示详细信息，不要隐藏错误）
        if sudo $PKG_MANAGER install -y libnftables 2>&1; then
          echo "✅ libnftables 安装成功，重新尝试安装 docker-ce..."
          if sudo $PKG_MANAGER install -y --allowerasing docker-ce 2>&1 | tee /tmp/docker-ce-install-retry.log; then
            echo "✅ docker-ce 安装成功（安装 libnftables 后）"
            DOCKER_CE_INSTALLED=true
          else
            echo "❌ docker-ce 安装仍然失败"
            DOCKER_CE_OUTPUT=$(cat /tmp/docker-ce-install-retry.log 2>/dev/null || echo "")
            
            # 如果仍然失败，尝试切换镜像源（不同镜像源可能有不同版本的 docker-ce）
            if echo "$DOCKER_CE_OUTPUT" | grep -qiE "libnftables|LIBNFTABLES"; then
              echo "⚠️  当前镜像源的 docker-ce 版本可能不兼容，尝试切换镜像源..."
              
              # 尝试切换其他镜像源（从阿里云开始，因为华为云已经失败）
              for mirror_idx in 1 2 3 4 5; do
                if switch_docker_mirror $mirror_idx; then
                  CURRENT_MIRROR_INDEX=$mirror_idx
                  echo "  - 重新尝试安装 docker-ce..."
                  
                  # 再次检查并安装 libnftables（某些镜像源可能提供不同版本）
                  if ! rpm -q libnftables >/dev/null 2>&1; then
                    echo "  - 安装 libnftables..."
                    sudo $PKG_MANAGER install -y libnftables 2>&1 || echo "  ⚠️  libnftables 安装失败，继续尝试安装 docker-ce..."
                  else
                    echo "  ✅ libnftables 已安装"
                  fi
                  
                  if sudo $PKG_MANAGER install -y --allowerasing docker-ce 2>&1 | tee /tmp/docker-ce-install-mirror.log; then
                    echo "✅ docker-ce 安装成功（切换镜像源后）"
                    DOCKER_CE_INSTALLED=true
                    break
                  else
                    echo "  ❌ 切换镜像源后仍然失败，尝试下一个镜像源..."
                  fi
                fi
              done
            fi
          fi
        else
          echo "⚠️  libnftables 安装失败，尝试切换镜像源后重试..."
          
          # 尝试切换其他镜像源
          for mirror_idx in 1 2 3 4 5; do
            if switch_docker_mirror $mirror_idx; then
              CURRENT_MIRROR_INDEX=$mirror_idx
              echo "  - 检查并安装 libnftables..."
              
              # 先检查是否已安装
              if rpm -q libnftables >/dev/null 2>&1; then
                echo "  ✅ libnftables 已安装"
              else
                # 尝试安装 libnftables（显示详细信息）
                if sudo $PKG_MANAGER install -y libnftables 2>&1; then
                  echo "  ✅ libnftables 安装成功"
                else
                  echo "  ⚠️  libnftables 安装失败，继续尝试安装 docker-ce..."
                fi
              fi
              
              # 无论 libnftables 是否安装成功，都尝试安装 docker-ce
              echo "  - 尝试安装 docker-ce..."
              if sudo $PKG_MANAGER install -y --allowerasing docker-ce 2>&1 | tee /tmp/docker-ce-install-mirror.log; then
                echo "✅ docker-ce 安装成功（切换镜像源后）"
                DOCKER_CE_INSTALLED=true
                break
              else
                echo "  ❌ docker-ce 安装仍然失败，尝试下一个镜像源..."
              fi
            fi
          done
          
          if [[ "$DOCKER_CE_INSTALLED" == "false" ]]; then
            echo "⚠️  所有镜像源都尝试失败，将使用二进制安装方式绕过依赖问题"
          fi
        fi
      fi
    fi
    
    if sudo $PKG_MANAGER install -y --allowerasing docker-buildx-plugin; then
      echo "✅ docker-buildx-plugin 安装成功"
    else
      echo "❌ docker-buildx-plugin 安装失败"
    fi
    
    # 检查 docker.service 文件是否存在
    DOCKER_SERVICE_EXISTS=false
    if [ -f /etc/systemd/system/docker.service ] || [ -f /usr/lib/systemd/system/docker.service ]; then
      DOCKER_SERVICE_EXISTS=true
    fi
    
    # 检查是否至少安装了核心组件
    # 不仅要检查 docker 命令是否存在，还要检查 docker.service 是否存在
    if ! command -v docker &> /dev/null || [ "$DOCKER_CE_INSTALLED" == "false" ] || [ "$DOCKER_SERVICE_EXISTS" == "false" ]; then
      if [ "$DOCKER_CE_INSTALLED" == "false" ] || [ "$DOCKER_SERVICE_EXISTS" == "false" ]; then
        if command -v docker &> /dev/null; then
          echo "⚠️  检测到 docker 命令存在，但 docker-ce 包或 docker.service 文件缺失"
          echo "⚠️  这通常是由于依赖问题导致 docker-ce 安装不完整"
        fi
        echo "❌ docker-ce 安装不完整，尝试二进制安装..."
      else
        echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      fi
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 华为云镜像（优先）
      echo "尝试从华为云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从华为云镜像下载成功"
      else
        echo "❌ 华为云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 阿里云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从阿里云镜像下载..."
        if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从阿里云镜像下载成功"
        else
          echo "❌ 阿里云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
    echo "正在解压并安装 Docker 二进制包..."
    sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
    sudo chmod +x /usr/bin/docker*
    
    # SELinux 友好提示
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        echo ""
        echo "⚠️  检测到 SELinux 处于开启状态 ($(getenforce))"
        echo "⚠️  二进制安装方式可能会遇到 SELinux 上下文问题"
        echo "⚠️  如果启动失败，请尝试临时关闭 SELinux (setenforce 0) 或手动配置 SELinux 策略"
        echo "💡 推荐操作：尝试安装 container-selinux >= 2.74"
        echo ""
        echo "正在等待 3 秒以确认切换到二进制安装模式..."
        sleep 3
    fi

    # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  # 检查 docker.service 文件是否存在
  if [ ! -f /etc/systemd/system/docker.service ] && [ ! -f /usr/lib/systemd/system/docker.service ]; then
    echo "❌ docker.service 文件不存在，Docker 服务无法启动"
    echo "⚠️  这通常是由于 docker-ce 包安装失败导致的"
    echo "💡 建议："
    echo "   1. 检查依赖问题（如 libnftables）"
    echo "   2. 尝试手动安装依赖：sudo $PKG_MANAGER install -y libnftables"
    echo "   3. 重新运行安装脚本"
    echo "   4. 或使用二进制安装方式"
    exit 1
  fi
  
  # 启动 Docker 服务
  echo "正在启动 Docker 服务..."
  if sudo systemctl enable docker 2>/dev/null; then
    echo "✅ Docker 服务已设置为开机自启"
  else
    echo "⚠️  Docker 服务开机自启设置失败"
  fi
  
  if sudo systemctl start docker 2>/dev/null; then
    echo "✅ Docker 服务启动成功"
  else
    echo "⚠️  Docker 服务启动失败，尝试查看日志..."
    sudo systemctl status docker --no-pager -l || true
    echo "💡 可以尝试手动启动：sudo dockerd &"
  fi
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 华为云镜像（优先）
  echo "尝试从华为云镜像下载..."
  if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从华为云镜像下载成功"
  else
    echo "❌ 华为云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 阿里云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从阿里云镜像下载..."
    if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从阿里云镜像下载成功"
    else
      echo "❌ 阿里云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo $PKG_MANAGER install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "opencloudos" ]]; then
  # OpenCloudOS 9 使用 dnf 而不是 yum
  sudo dnf install -y dnf-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 OpenCloudOS 9 兼容的版本
  echo "正在创建 Docker 仓库配置..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo dnf makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 临时禁用 set -e，允许错误处理
  set +e
  
  echo "正在尝试安装 Docker CE（这可能需要几分钟，请耐心等待）..."
  echo "如果安装过程卡住，可能是网络问题或依赖解析中，请等待..."
  
  # 尝试安装 Docker，使用超时机制（30分钟超时）
  INSTALL_OUTPUT=""
  INSTALL_STATUS=1
  
  # 使用 timeout 命令（如果可用）或直接执行
  # 注意：使用 bash -c 确保 sudo 函数在子 shell 中可用
  if command -v timeout &> /dev/null; then
    INSTALL_OUTPUT=$(timeout 1800 bash -c "sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin" 2>&1)
    INSTALL_STATUS=$?
    if [[ $INSTALL_STATUS -eq 124 ]]; then
      echo "❌ 安装超时（30分钟），可能是网络问题或依赖解析失败"
      INSTALL_STATUS=1
    fi
  else
    INSTALL_OUTPUT=$(sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>&1)
    INSTALL_STATUS=$?
  fi
  
  # 重新启用 set -e
  set -e
  
  if [[ $INSTALL_STATUS -eq 0 ]]; then
    echo "✅ Docker CE 安装成功"
  else
    # 显示详细错误信息
    echo ""
    echo "❌ Docker CE 批量安装失败"
    echo "错误详情："
    echo "$INSTALL_OUTPUT" | tail -20
    echo ""
    
    # 检查错误类型
    if echo "$INSTALL_OUTPUT" | grep -qiE "(timeout|timed out|connection|网络|network)"; then
      echo "⚠️  检测到可能的网络问题，请检查网络连接"
    fi
    if echo "$INSTALL_OUTPUT" | grep -qiE "(repo|repository|仓库|not found|找不到)"; then
      echo "⚠️  检测到可能的仓库配置问题，请检查 Docker 源配置"
    fi
    
    echo "正在尝试逐个安装组件..."
    
    # 临时禁用 set -e
    set +e
    
    # 逐个安装组件
    echo "  - 正在安装 containerd.io..."
    CONTAINERD_OUTPUT=$(sudo dnf install -y containerd.io 2>&1)
    CONTAINERD_STATUS=$?
    if [[ $CONTAINERD_STATUS -eq 0 ]]; then
      echo "  ✅ containerd.io 安装成功"
    else
      echo "  ❌ containerd.io 安装失败"
      echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce-cli..."
    DOCKER_CLI_OUTPUT=$(sudo dnf install -y docker-ce-cli 2>&1)
    DOCKER_CLI_STATUS=$?
    if [[ $DOCKER_CLI_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce-cli 安装成功"
    else
      echo "  ❌ docker-ce-cli 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CLI_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce..."
    DOCKER_CE_OUTPUT=$(sudo dnf install -y docker-ce 2>&1)
    DOCKER_CE_STATUS=$?
    if [[ $DOCKER_CE_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce 安装成功"
    else
      echo "  ❌ docker-ce 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-buildx-plugin..."
    BUILDX_OUTPUT=$(sudo dnf install -y docker-buildx-plugin 2>&1)
    BUILDX_STATUS=$?
    if [[ $BUILDX_STATUS -eq 0 ]]; then
      echo "  ✅ docker-buildx-plugin 安装成功"
    else
      echo "  ⚠️  docker-buildx-plugin 安装失败（可选组件，不影响核心功能）"
    fi
    
    # 重新启用 set -e
    set -e
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo ""
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 阿里云镜像
  echo "尝试从阿里云镜像下载..."
  if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从阿里云镜像下载成功"
  else
    echo "❌ 阿里云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从华为云镜像下载..."
    if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从华为云镜像下载成功"
    else
      echo "❌ 华为云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo dnf install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "anolis" ]]; then
  # Anolis OS (龙蜥操作系统) 支持
  echo "检测到 Anolis OS (龙蜥操作系统) $VERSION_ID"
  
  # 判断使用 dnf 还是 yum
  if [[ "${VERSION_ID%%.*}" -ge 8 ]]; then
    # Anolis 8+ 使用 dnf
    PKG_MANAGER="dnf"
    CENTOS_VERSION="8"
    echo "使用 dnf 包管理器 (Anolis $VERSION_ID 基于 CentOS 8+)"
  else
    # Anolis 7 使用 yum
    PKG_MANAGER="yum"
    CENTOS_VERSION="7"
    echo "使用 yum 包管理器 (Anolis $VERSION_ID 基于 CentOS 7)"
  fi
  
  sudo $PKG_MANAGER install -y ${PKG_MANAGER}-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 Anolis 兼容的 CentOS 版本
  echo "正在创建 Docker 仓库配置 (使用 CentOS ${CENTOS_VERSION} 兼容源)..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo $PKG_MANAGER makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 尝试安装 Docker，如果失败则尝试逐个安装组件
  if sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin; then
    echo "✅ Docker CE 安装成功"
  else
    echo "❌ 批量安装失败，尝试逐个安装组件..."
    
    # 逐个安装组件
    if sudo $PKG_MANAGER install -y containerd.io; then
      echo "✅ containerd.io 安装成功"
    else
      echo "❌ containerd.io 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-ce-cli; then
      echo "✅ docker-ce-cli 安装成功"
    else
      echo "❌ docker-ce-cli 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-ce; then
      echo "✅ docker-ce 安装成功"
    else
      echo "❌ docker-ce 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-buildx-plugin; then
      echo "✅ docker-buildx-plugin 安装成功"
    else
      echo "❌ docker-buildx-plugin 安装失败"
    fi
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 阿里云镜像
  echo "尝试从阿里云镜像下载..."
  if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从阿里云镜像下载成功"
  else
    echo "❌ 阿里云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从华为云镜像下载..."
    if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从华为云镜像下载成功"
    else
      echo "❌ 华为云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo $PKG_MANAGER install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "alinux" ]]; then
  # Alinux (Alibaba Cloud Linux) 支持
  echo "检测到 Alibaba Cloud Linux (Alinux) $VERSION_ID"
  echo "基于 Anolis OS，阿里云深度优化的企业级操作系统"
  
  # 判断使用 dnf 还是 yum
  if [[ "${VERSION_ID%%.*}" -ge 3 ]]; then
    # Alinux 3+ 使用 dnf，基于 Anolis OS 8
    PKG_MANAGER="dnf"
    CENTOS_VERSION="8"
    echo "使用 dnf 包管理器 (Alinux $VERSION_ID 基于 Anolis OS 8 / CentOS 8)"
  else
    # Alinux 2 使用 yum，基于 Anolis OS 7
    PKG_MANAGER="yum"
    CENTOS_VERSION="7"
    echo "使用 yum 包管理器 (Alinux $VERSION_ID 基于 Anolis OS 7 / CentOS 7)"
  fi
  
  sudo $PKG_MANAGER install -y ${PKG_MANAGER}-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 Alinux 兼容的 CentOS 版本
  echo "正在创建 Docker 仓库配置 (使用 CentOS ${CENTOS_VERSION} 兼容源)..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo $PKG_MANAGER makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 尝试安装 Docker，如果失败则尝试逐个安装组件
  if sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin; then
    echo "✅ Docker CE 安装成功"
  else
    echo "❌ 批量安装失败，尝试逐个安装组件..."
    
    # 逐个安装组件
    if sudo $PKG_MANAGER install -y containerd.io; then
      echo "✅ containerd.io 安装成功"
    else
      echo "❌ containerd.io 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-ce-cli; then
      echo "✅ docker-ce-cli 安装成功"
    else
      echo "❌ docker-ce-cli 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-ce; then
      echo "✅ docker-ce 安装成功"
    else
      echo "❌ docker-ce 安装失败"
    fi
    
    if sudo $PKG_MANAGER install -y docker-buildx-plugin; then
      echo "✅ docker-buildx-plugin 安装成功"
    else
      echo "❌ docker-buildx-plugin 安装失败"
    fi
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 阿里云镜像
  echo "尝试从阿里云镜像下载..."
  if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从阿里云镜像下载成功"
  else
    echo "❌ 阿里云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从华为云镜像下载..."
    if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从华为云镜像下载成功"
    else
      echo "❌ 华为云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo $PKG_MANAGER install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "fedora" ]]; then
  # Fedora 支持
  echo "检测到 Fedora $VERSION_ID"
  
  # 检查 Fedora 版本是否过期
  if [[ "${VERSION_ID%%.*}" -lt 38 ]]; then
    echo ""
    echo "⚠️  警告：Fedora $VERSION_ID 可能已结束生命周期"
    echo "📋 建议："
    echo "   - 升级到 Fedora 38+ 以获得最新的安全更新和软件包"
    echo "   - 或考虑使用 Rocky Linux / AlmaLinux（企业级长期支持）"
    echo ""
  fi
  
  # Fedora 使用 dnf 包管理器
  sudo dnf install -y dnf-plugins-core
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 Fedora 专用仓库
  echo "正在创建 Docker 仓库配置..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/fedora/gpg
EOF
  
  if sudo dnf makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/fedora/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/fedora/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/fedora/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/fedora/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 尝试安装 Docker，如果失败则尝试逐个安装组件
  if sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo "✅ Docker CE 安装成功"
  else
    echo "❌ 批量安装失败，尝试逐个安装组件..."
    
    # 逐个安装组件
    if sudo dnf install -y containerd.io; then
      echo "✅ containerd.io 安装成功"
    else
      echo "❌ containerd.io 安装失败"
    fi
    
    if sudo dnf install -y docker-ce-cli; then
      echo "✅ docker-ce-cli 安装成功"
    else
      echo "❌ docker-ce-cli 安装失败"
    fi
    
    if sudo dnf install -y docker-ce; then
      echo "✅ docker-ce 安装成功"
    else
      echo "❌ docker-ce 安装失败"
    fi
    
    if sudo dnf install -y docker-buildx-plugin; then
      echo "✅ docker-buildx-plugin 安装成功"
    else
      echo "❌ docker-buildx-plugin 安装失败（可选组件）"
    fi
    
    if sudo dnf install -y docker-compose-plugin; then
      echo "✅ docker-compose-plugin 安装成功"
    else
      echo "❌ docker-compose-plugin 安装失败（可选组件）"
    fi
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 检查是否已通过插件安装
  if command -v docker compose version &> /dev/null 2>&1; then
    echo "✅ Docker Compose (插件版本) 已安装"
  else
    # 安装独立版本的 docker-compose，使用多个备用下载源
    echo "正在下载 Docker Compose 独立版本..."
    
    # 尝试多个下载源
    DOCKER_COMPOSE_DOWNLOADED=false
    
    # 源1: 阿里云镜像
    echo "尝试从阿里云镜像下载..."
    if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从阿里云镜像下载成功"
    else
      echo "❌ 阿里云镜像下载失败，尝试下一个源..."
    fi
    
    # 源2: 腾讯云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从腾讯云镜像下载..."
      if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从腾讯云镜像下载成功"
      else
        echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源3: 华为云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从华为云镜像下载..."
      if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从华为云镜像下载成功"
      else
        echo "❌ 华为云镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源4: 中科大镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从中科大镜像下载..."
      if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从中科大镜像下载成功"
      else
        echo "❌ 中科大镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源5: 清华大学镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从清华大学镜像下载..."
      if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从清华大学镜像下载成功"
      else
        echo "❌ 清华大学镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源6: 网易镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从网易镜像下载..."
      if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从网易镜像下载成功"
      else
        echo "❌ 网易镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源7: 最后尝试 GitHub (如果网络允许)
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从 GitHub 下载..."
      if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从 GitHub 下载成功"
      else
        echo "❌ GitHub 下载失败"
      fi
    fi
    
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
      # 设置执行权限
      sudo chmod +x /usr/local/bin/docker-compose
      
      # 创建软链接到 PATH 目录
      sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
      
      echo "✅ Docker Compose 独立版本安装完成"
    else
      echo "⚠️  Docker Compose 独立版本安装失败"
      echo "您仍可以使用 'docker compose' 命令（如果插件已安装）"
    fi
  fi

elif [[ "$OS" == "rocky" ]]; then
  # Rocky Linux 9 使用 dnf 而不是 yum
  sudo dnf install -y dnf-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 Rocky Linux 9 兼容的版本
  echo "正在创建 Docker 仓库配置..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo dnf makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 临时禁用 set -e，允许错误处理
  set +e
  
  echo "正在尝试安装 Docker CE（这可能需要几分钟，请耐心等待）..."
  echo "如果安装过程卡住，可能是网络问题或依赖解析中，请等待..."
  
  # 尝试安装 Docker，使用超时机制（30分钟超时）
  INSTALL_OUTPUT=""
  INSTALL_STATUS=1
  
  # 使用 timeout 命令（如果可用）或直接执行
  # 注意：使用 bash -c 确保 sudo 函数在子 shell 中可用
  if command -v timeout &> /dev/null; then
    INSTALL_OUTPUT=$(timeout 1800 bash -c "sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin" 2>&1)
    INSTALL_STATUS=$?
    if [[ $INSTALL_STATUS -eq 124 ]]; then
      echo "❌ 安装超时（30分钟），可能是网络问题或依赖解析失败"
      INSTALL_STATUS=1
    fi
  else
    INSTALL_OUTPUT=$(sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>&1)
    INSTALL_STATUS=$?
  fi
  
  # 重新启用 set -e
  set -e
  
  if [[ $INSTALL_STATUS -eq 0 ]]; then
    echo "✅ Docker CE 安装成功"
  else
    # 显示详细错误信息
    echo ""
    echo "❌ Docker CE 批量安装失败"
    echo "错误详情："
    echo "$INSTALL_OUTPUT" | tail -20
    echo ""
    
    # 检查错误类型
    if echo "$INSTALL_OUTPUT" | grep -qiE "(timeout|timed out|connection|网络|network)"; then
      echo "⚠️  检测到可能的网络问题，请检查网络连接"
    fi
    if echo "$INSTALL_OUTPUT" | grep -qiE "(repo|repository|仓库|not found|找不到)"; then
      echo "⚠️  检测到可能的仓库配置问题，请检查 Docker 源配置"
    fi
    
    echo "正在尝试逐个安装组件..."
    
    # 临时禁用 set -e
    set +e
    
    # 逐个安装组件
    echo "  - 正在安装 containerd.io..."
    CONTAINERD_OUTPUT=$(sudo dnf install -y containerd.io 2>&1)
    CONTAINERD_STATUS=$?
    if [[ $CONTAINERD_STATUS -eq 0 ]]; then
      echo "  ✅ containerd.io 安装成功"
    else
      echo "  ❌ containerd.io 安装失败"
      echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce-cli..."
    DOCKER_CLI_OUTPUT=$(sudo dnf install -y docker-ce-cli 2>&1)
    DOCKER_CLI_STATUS=$?
    if [[ $DOCKER_CLI_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce-cli 安装成功"
    else
      echo "  ❌ docker-ce-cli 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CLI_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce..."
    DOCKER_CE_OUTPUT=$(sudo dnf install -y docker-ce 2>&1)
    DOCKER_CE_STATUS=$?
    if [[ $DOCKER_CE_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce 安装成功"
    else
      echo "  ❌ docker-ce 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-buildx-plugin..."
    BUILDX_OUTPUT=$(sudo dnf install -y docker-buildx-plugin 2>&1)
    BUILDX_STATUS=$?
    if [[ $BUILDX_STATUS -eq 0 ]]; then
      echo "  ✅ docker-buildx-plugin 安装成功"
    else
      echo "  ⚠️  docker-buildx-plugin 安装失败（可选组件，不影响核心功能）"
    fi
    
    # 重新启用 set -e
    set -e
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo ""
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 阿里云镜像
  echo "尝试从阿里云镜像下载..."
  if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从阿里云镜像下载成功"
  else
    echo "❌ 阿里云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从华为云镜像下载..."
    if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从华为云镜像下载成功"
    else
      echo "❌ 华为云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo dnf install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "kylin" || "$OS" == "uos" || "$OS" == "uniontechos" ]]; then
  # Kylin Linux（银河麒麟）/ 统信 UOS：RHEL 兼容系，Docker CE 使用 linux/centos/${CENTOS_VERSION} 源
  KYLIN_MAJOR_VERSION=""
  UOS_PRESET_CENTOS=""
  if [[ "$OS" == "kylin" ]]; then
    # 规范显示版本号，避免 Vv10
    if [[ "$VERSION_ID" =~ ^[Vv] ]]; then
      KYLIN_VERSION_DISPLAY="$VERSION_ID"
    else
      KYLIN_VERSION_DISPLAY="V$VERSION_ID"
    fi
    echo "检测到 Kylin Linux $KYLIN_VERSION_DISPLAY"
    echo "Kylin Linux 基于 RHEL，与 CentOS/RHEL 兼容"
    # 对银河麒麟版本做简单解析：V10 系列按 RHEL 8 处理
    if [[ "$VERSION_ID" =~ [0-9]+ ]]; then
      KYLIN_MAJOR_VERSION="$(echo "$VERSION_ID" | grep -oE '[0-9]+' | head -1)"
    fi
  else
    echo "检测到统信 UOS $VERSION_ID（/etc/os-release ID=$OS）"
    echo "统信服务器版与 RHEL/CentOS 兼容；Docker CE 使用 CentOS 兼容仓库"
    # UOS 20.x 等与 EL8 线兼容，不得沿用「首个数字」误判为 7（VERSION_ID=20 时首段为 20 而非 10）
    UOS_MAJOR="${VERSION_ID%%.*}"
    if [[ "$UOS_MAJOR" =~ ^[0-9]+$ ]] && [[ "$UOS_MAJOR" -ge 20 ]]; then
      UOS_PRESET_CENTOS="8"
    else
      UOS_PRESET_CENTOS="7"
    fi
    echo "兼容映射：使用 CentOS ${UOS_PRESET_CENTOS} 的 Docker CE 源（若失败请反馈 VERSION_ID 以便调整）"
  fi

  # 优先使用 dnf，其次尝试 yum；都不存在则提示用户
  if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    if [[ -n "$UOS_PRESET_CENTOS" ]]; then
      CENTOS_VERSION="$UOS_PRESET_CENTOS"
    elif [[ "$KYLIN_MAJOR_VERSION" == "10" ]]; then
      CENTOS_VERSION="8"
    else
      CENTOS_VERSION="7"
    fi
    if [[ "$OS" == "kylin" ]]; then
      echo "使用 dnf 包管理器 (Kylin $KYLIN_VERSION_DISPLAY 基于 RHEL ${CENTOS_VERSION})"
    else
      echo "使用 dnf 包管理器 (UOS $VERSION_ID → CentOS ${CENTOS_VERSION} 兼容源)"
    fi
  elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    if [[ -n "$UOS_PRESET_CENTOS" ]]; then
      CENTOS_VERSION="$UOS_PRESET_CENTOS"
    elif [[ "$KYLIN_MAJOR_VERSION" == "10" ]]; then
      CENTOS_VERSION="8"
    else
      CENTOS_VERSION="7"
    fi
    if [[ "$OS" == "kylin" ]]; then
      echo "使用 yum 包管理器 (Kylin $KYLIN_VERSION_DISPLAY 基于 RHEL ${CENTOS_VERSION})"
    else
      echo "使用 yum 包管理器 (UOS $VERSION_ID → CentOS ${CENTOS_VERSION} 兼容源)"
    fi
  else
    echo "❌ 未检测到可用的 dnf 或 yum 包管理器，请先在系统中安装 dnf 或 yum 后重试。"
    exit 1
  fi
  
  sudo $PKG_MANAGER install -y ${PKG_MANAGER}-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用兼容的 CentOS 版本
  echo "正在创建 Docker 仓库配置 (使用 CentOS ${CENTOS_VERSION} 兼容源)..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo $PKG_MANAGER makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo $PKG_MANAGER makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [2.5/8] 检查 container-selinux 依赖..."
  # 检查 container-selinux 是否存在及版本
  CONTAINER_SELINUX_INSTALLED=false
  if rpm -q container-selinux &>/dev/null; then
    INSTALLED_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}' container-selinux 2>/dev/null)
    echo "检测到已安装 container-selinux: $INSTALLED_VERSION"
    # 检查版本是否满足要求 (>= 2.74)
    # 尝试解析版本号，格式可能是 2:2.74-1 或 2.74-1
    VERSION_STRING=$(echo "$INSTALLED_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$VERSION_STRING" ]]; then
      MAJOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f1)
      MINOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f2)
      if [[ "$MAJOR_VERSION" -gt 2 ]] || [[ "$MAJOR_VERSION" -eq 2 && "$MINOR_VERSION" -ge 74 ]]; then
        CONTAINER_SELINUX_INSTALLED=true
        echo "✅ container-selinux 版本满足要求"
      else
        echo "⚠️  container-selinux 版本过低 ($INSTALLED_VERSION)，需要 >= 2:2.74"
      fi
    else
      # 如果无法解析版本，尝试安装最新版本
      echo "⚠️  无法解析 container-selinux 版本，将尝试更新"
    fi
  else
    echo "未检测到 container-selinux，将尝试安装..."
  fi
  
  # 如果 container-selinux 未安装或版本不够，尝试安装
  if [[ "$CONTAINER_SELINUX_INSTALLED" == "false" ]]; then
    echo "正在尝试安装 container-selinux..."
    
    # 方法1: 尝试从系统源安装
    if sudo $PKG_MANAGER install -y container-selinux 2>/dev/null; then
      echo "✅ 从系统源安装 container-selinux 成功"
      # 重新检查版本
      INSTALLED_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}' container-selinux 2>/dev/null)
      echo "已安装版本: $INSTALLED_VERSION"
      VERSION_STRING=$(echo "$INSTALLED_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1)
      if [[ -n "$VERSION_STRING" ]]; then
        MAJOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f1)
        MINOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f2)
        if [[ "$MAJOR_VERSION" -gt 2 ]] || [[ "$MAJOR_VERSION" -eq 2 && "$MINOR_VERSION" -ge 74 ]]; then
          CONTAINER_SELINUX_INSTALLED=true
          echo "✅ container-selinux 版本满足要求"
        else
          echo "⚠️  container-selinux 版本过低 ($INSTALLED_VERSION)，需要 >= 2:2.74"
          echo "⚠️  将尝试从其他源安装更高版本..."
        fi
      fi
    else
      echo "⚠️  系统源中未找到 container-selinux，尝试配置 RHEL 8 extras 源..."
    fi
    
    # 方法2: 如果版本仍然不满足要求，尝试配置 RHEL 8 extras 源（适用于 Kylin V10）
    if [[ "$CONTAINER_SELINUX_INSTALLED" == "false" && "$CENTOS_VERSION" == "8" ]]; then
      echo "尝试配置 RHEL 8 extras 源以获取更高版本的 container-selinux..."
      # 尝试配置阿里云 CentOS 8 extras 源
      if sudo tee /etc/yum.repos.d/rhel8-extras.repo > /dev/null <<EOF 2>/dev/null; then
[rhel8-extras]
name=RHEL 8 Extras - \$basearch
baseurl=https://mirrors.aliyun.com/centos-vault/8.5.2111/extras/\$basearch/os/
enabled=1
gpgcheck=0
EOF
        if sudo $PKG_MANAGER makecache -q 2>/dev/null; then
          # 尝试升级到更高版本
          if sudo $PKG_MANAGER upgrade -y container-selinux 2>/dev/null || sudo $PKG_MANAGER install -y container-selinux 2>/dev/null; then
            INSTALLED_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}' container-selinux 2>/dev/null)
            echo "已安装版本: $INSTALLED_VERSION"
            VERSION_STRING=$(echo "$INSTALLED_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1)
            if [[ -n "$VERSION_STRING" ]]; then
              MAJOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f1)
              MINOR_VERSION=$(echo "$VERSION_STRING" | cut -d. -f2)
              if [[ "$MAJOR_VERSION" -gt 2 ]] || [[ "$MAJOR_VERSION" -eq 2 && "$MINOR_VERSION" -ge 74 ]]; then
                CONTAINER_SELINUX_INSTALLED=true
                echo "✅ 从 RHEL 8 extras 源安装 container-selinux 成功，版本满足要求"
              else
                echo "⚠️  RHEL 8 extras 源版本仍然不满足要求"
              fi
            fi
          else
            echo "⚠️  RHEL 8 extras 源安装失败"
          fi
        else
          echo "⚠️  RHEL 8 extras 源配置失败"
        fi
        sudo rm -f /etc/yum.repos.d/rhel8-extras.repo 2>/dev/null
      fi
    fi
    
    # 方法3: 如果版本仍然不满足要求，标记为需要二进制安装
    if [[ "$CONTAINER_SELINUX_INSTALLED" == "false" ]]; then
      echo "⚠️  container-selinux 版本不满足要求（需要 >= 2:2.74）"
      echo "⚠️  将使用二进制安装方式绕过依赖问题"
      CONTAINER_SELINUX_ERROR=true
    fi
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."

  # 统信 UOS / 银河麒麟等自带的 docker-runc 与 Docker CE 的 containerd.io（内置 runc）冲突，需先移除再装 docker-ce
  if [[ "$OS" == "uos" || "$OS" == "uniontechos" || "$OS" == "kylin" ]]; then
    if rpm -q docker-runc &>/dev/null; then
      echo ">>> [2.9/8] 检测到系统包 docker-runc，与 Docker CE 依赖冲突，正在移除..."
      sudo $PKG_MANAGER remove -y docker-runc 2>/dev/null || true
    fi
  fi
  
  # 如果 container-selinux 版本不满足要求，直接使用二进制安装
  DOCKER_INSTALL_SUCCESS=false
  
  # 如果已经检测到 container-selinux 错误，直接跳过包管理器安装
  if [[ "$CONTAINER_SELINUX_ERROR" == "true" ]]; then
    echo ""
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo "⚠️  检测到 container-selinux 版本不满足要求"
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo "⚠️  Docker CE 需要 container-selinux >= 2:2.74，但系统源中无法提供"
    echo "⚠️  将使用二进制安装方式绕过依赖问题"
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # 清理可能的安装残留
    sudo $PKG_MANAGER remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>/dev/null || true
    
    echo "❌ 包管理器安装失败，切换到二进制安装..."
  else
    # 临时禁用 set -e，允许错误处理
    set +e
    
    echo "正在尝试安装 Docker CE（这可能需要几分钟，请耐心等待）..."
    echo "如果安装过程卡住，可能是网络问题或依赖解析中，请等待..."
    
    # 尝试安装 Docker，使用超时机制（30分钟超时）
    INSTALL_OUTPUT=""
    INSTALL_STATUS=1
    
    # 使用 timeout 命令（如果可用）或直接执行
    # 注意：使用 bash -c 确保 sudo 函数在子 shell 中可用
    if command -v timeout &> /dev/null; then
      INSTALL_OUTPUT=$(timeout 1800 bash -c "sudo $PKG_MANAGER install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin" 2>&1)
      INSTALL_STATUS=$?
      if [[ $INSTALL_STATUS -eq 124 ]]; then
        echo "❌ 安装超时（30分钟），可能是网络问题或依赖解析失败"
        INSTALL_STATUS=1
      fi
    else
      INSTALL_OUTPUT=$(sudo $PKG_MANAGER install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>&1)
      INSTALL_STATUS=$?
    fi
    
    # 重新启用 set -e
    set -e
    
    if [[ $INSTALL_STATUS -eq 0 ]]; then
      echo "✅ Docker CE 安装成功"
      DOCKER_INSTALL_SUCCESS=true
    else
      # 显示详细错误信息
      echo ""
      echo "❌ Docker CE 批量安装失败"
      echo "错误详情："
      echo "$INSTALL_OUTPUT" | tail -20
      echo ""
      
      # 检查错误输出，判断是否是 container-selinux 依赖问题
      if echo "$INSTALL_OUTPUT" | grep -qi "container-selinux"; then
        CONTAINER_SELINUX_ERROR=true
        echo "❌ 检测到 container-selinux 依赖问题"
      fi
      
      # 检查是否是网络问题
      if echo "$INSTALL_OUTPUT" | grep -qiE "(timeout|timed out|connection|网络|network)"; then
        echo "⚠️  检测到可能的网络问题，请检查网络连接"
      fi
      
      # 检查是否是仓库问题
      if echo "$INSTALL_OUTPUT" | grep -qiE "(repo|repository|仓库|not found|找不到)"; then
        echo "⚠️  检测到可能的仓库配置问题，请检查 Docker 源配置"
      fi
      
      echo "正在尝试逐个安装组件..."
      
      # 临时禁用 set -e
      set +e
      
      # 逐个安装组件
      echo "  - 正在安装 containerd.io..."
      CONTAINERD_OUTPUT=$(sudo $PKG_MANAGER install -y containerd.io 2>&1)
      CONTAINERD_STATUS=$?
      if echo "$CONTAINERD_OUTPUT" | grep -qi "container-selinux"; then
        echo "  ❌ containerd.io 安装失败（container-selinux 依赖问题）"
        echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | grep -i "container-selinux" | head -1)"
        CONTAINER_SELINUX_ERROR=true
      elif [[ $CONTAINERD_STATUS -eq 0 ]]; then
        echo "  ✅ containerd.io 安装成功"
      else
        echo "  ❌ containerd.io 安装失败"
        echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | tail -5)"
        
        # 检测下载失败或校验和不匹配，尝试清理缓存后重试
        if echo "$CONTAINERD_OUTPUT" | grep -qiE "(Cannot download|all mirrors were already tried|下载失败|无法下载|checksum doesn't match|校验和不匹配)"; then
          echo "  ⚠️  检测到下载失败或校验和不匹配，尝试清理缓存后重试..."
          # 清理所有缓存，包括损坏的文件
          sudo $PKG_MANAGER clean all 2>/dev/null || true
          sudo rm -rf /var/cache/dnf/* 2>/dev/null || true
          sudo rm -rf /var/cache/yum/* 2>/dev/null || true
          echo "  - 重新尝试安装 containerd.io..."
          CONTAINERD_RETRY_OUTPUT=$(sudo $PKG_MANAGER install -y containerd.io 2>&1)
          CONTAINERD_RETRY_STATUS=$?
          if [[ $CONTAINERD_RETRY_STATUS -eq 0 ]]; then
            echo "  ✅ containerd.io 重试安装成功"
            CONTAINERD_STATUS=0
          else
            echo "  ❌ containerd.io 重试安装仍然失败"
            echo "  错误信息: $(echo "$CONTAINERD_RETRY_OUTPUT" | tail -5)"
            
            # 如果还是校验和不匹配，尝试安装其他版本
            if echo "$CONTAINERD_RETRY_OUTPUT" | grep -qiE "(checksum doesn't match|校验和不匹配)"; then
              echo "  ⚠️  检测到校验和不匹配，尝试安装其他版本的 containerd.io..."
              
              # 尝试多个可用版本（从新到旧）
              CONTAINERD_VERSIONS=("1.6.31-3.1.el8" "1.6.28-3.2.el8" "1.6.28-3.1.el8" "1.6.27-3.1.el8" "1.6.26-3.1.el8")
              CONTAINERD_INSTALLED=false
              
              for VERSION in "${CONTAINERD_VERSIONS[@]}"; do
                echo "  - 尝试安装 containerd.io-${VERSION}..."
                CONTAINERD_ALT_OUTPUT=$(sudo $PKG_MANAGER install -y containerd.io-${VERSION} 2>&1)
                CONTAINERD_ALT_STATUS=$?
                if [[ $CONTAINERD_ALT_STATUS -eq 0 ]]; then
                  echo "  ✅ containerd.io-${VERSION} 安装成功"
                  CONTAINERD_STATUS=0
                  CONTAINERD_INSTALLED=true
                  break
                else
                  # 检查是否是校验和不匹配，如果是则继续尝试下一个版本
                  if echo "$CONTAINERD_ALT_OUTPUT" | grep -qiE "(checksum doesn't match|校验和不匹配)"; then
                    echo "  ⚠️  containerd.io-${VERSION} 也存在校验和不匹配，尝试下一个版本..."
                    continue
                  else
                    echo "  ❌ containerd.io-${VERSION} 安装失败"
                    # 如果不是校验和问题，可能是其他问题，继续尝试下一个版本
                    continue
                  fi
                fi
              done
              
              if [[ "$CONTAINERD_INSTALLED" == "false" ]]; then
                echo "  ❌ 所有尝试的版本都安装失败"
                echo "  💡 建议：手动下载并安装 containerd.io"
                echo "    下载地址：https://mirrors.aliyun.com/docker-ce/linux/centos/8/${DOCKER_ARCH}/stable/Packages/"
                echo "    或尝试其他镜像源："
                echo "    - 腾讯云：https://mirrors.cloud.tencent.com/docker-ce/linux/centos/8/${DOCKER_ARCH}/stable/Packages/"
                echo "    - 华为云：https://mirrors.huaweicloud.com/docker-ce/linux/centos/8/${DOCKER_ARCH}/stable/Packages/"
                echo "    安装命令：sudo rpm -ivh containerd.io-*.rpm"
              fi
            else
              echo "  ⚠️  提示：containerd.io 是 Docker 的运行时依赖，如果无法安装，Docker daemon 可能无法启动"
              echo "  💡 建议：检查网络连接或尝试手动安装 containerd.io"
            fi
          fi
        fi
      fi
      
      echo "  - 正在安装 docker-ce-cli..."
      DOCKER_CLI_OUTPUT=$(sudo $PKG_MANAGER install -y docker-ce-cli 2>&1)
      DOCKER_CLI_STATUS=$?
      if [[ $DOCKER_CLI_STATUS -eq 0 ]]; then
        echo "  ✅ docker-ce-cli 安装成功"
      else
        echo "  ❌ docker-ce-cli 安装失败"
        echo "  错误信息: $(echo "$DOCKER_CLI_OUTPUT" | tail -5)"
      fi
      
      echo "  - 正在安装 docker-ce..."
      DOCKER_CE_OUTPUT=$(sudo $PKG_MANAGER install -y --allowerasing docker-ce 2>&1)
      DOCKER_CE_STATUS=$?
      if echo "$DOCKER_CE_OUTPUT" | grep -qi "container-selinux"; then
        echo "  ❌ docker-ce 安装失败（container-selinux 依赖问题）"
        echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | grep -i "container-selinux" | head -1)"
        CONTAINER_SELINUX_ERROR=true
      elif [[ $DOCKER_CE_STATUS -eq 0 ]]; then
        echo "  ✅ docker-ce 安装成功"
        DOCKER_INSTALL_SUCCESS=true
      else
        echo "  ❌ docker-ce 安装失败"
        echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | tail -5)"
      fi
      
      echo "  - 正在安装 docker-buildx-plugin..."
      BUILDX_OUTPUT=$(sudo $PKG_MANAGER install -y docker-buildx-plugin 2>&1)
      BUILDX_STATUS=$?
      if [[ $BUILDX_STATUS -eq 0 ]]; then
        echo "  ✅ docker-buildx-plugin 安装成功"
      else
        echo "  ⚠️  docker-buildx-plugin 安装失败（可选组件，不影响核心功能）"
      fi
      
      # 重新启用 set -e
      set -e
      
      # 检查是否至少安装了核心组件
      if command -v docker &> /dev/null; then
        DOCKER_INSTALL_SUCCESS=true
        echo ""
        echo "✅ Docker 核心组件已安装（docker 命令可用）"
        
        # 检查安装状态并给出提示
        if [[ $CONTAINERD_STATUS -ne 0 ]] || [[ $DOCKER_CE_STATUS -ne 0 ]]; then
          echo ""
          echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
          echo "⚠️  部分组件安装失败"
          echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
          if [[ $CONTAINERD_STATUS -ne 0 ]]; then
            echo "⚠️  containerd.io 未安装 - Docker daemon 需要此组件才能运行"
          fi
          if [[ $DOCKER_CE_STATUS -ne 0 ]]; then
            echo "⚠️  docker-ce 未安装 - Docker daemon 需要此组件才能运行"
          fi
          echo ""
          echo "📋 当前状态："
          echo "   ✅ docker-ce-cli 已安装（可以使用 docker 命令）"
          echo "   ✅ docker-buildx-plugin 已安装"
          if [[ $CONTAINERD_STATUS -ne 0 ]]; then
            echo "   ❌ containerd.io 未安装"
          else
            echo "   ✅ containerd.io 已安装"
          fi
          if [[ $DOCKER_CE_STATUS -ne 0 ]]; then
            echo "   ❌ docker-ce 未安装"
          else
            echo "   ✅ docker-ce 已安装"
          fi
          echo ""
          echo "💡 建议操作："
          if [[ $CONTAINERD_STATUS -ne 0 ]]; then
            echo "   1. 手动安装 containerd.io："
            echo "      sudo $PKG_MANAGER clean all"
            echo "      sudo $PKG_MANAGER makecache"
            echo "      sudo $PKG_MANAGER install -y containerd.io"
          fi
          if [[ $DOCKER_CE_STATUS -ne 0 ]]; then
            echo "   2. 安装 containerd.io 后，再安装 docker-ce："
            echo "      sudo $PKG_MANAGER install -y docker-ce"
          fi
          echo "   3. 或者检查网络连接后重新运行安装脚本"
          echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
        fi
      fi
    fi
  fi
  
  # 如果检测到 container-selinux 依赖问题，使用二进制安装
  if [[ "$CONTAINER_SELINUX_ERROR" == "true" ]]; then
    echo ""
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo "⚠️  检测到 container-selinux 依赖问题"
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo "⚠️  Docker CE 需要 container-selinux >= 2:2.74，但系统源中无法提供"
    echo "⚠️  将使用二进制安装方式绕过依赖问题"
    echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # 清理可能的安装残留
    sudo $PKG_MANAGER remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>/dev/null || true
    
    echo "❌ 包管理器安装失败，切换到二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        # 尝试安装 containerd.io（如果可能）
        echo "正在尝试安装 containerd.io..."
        if sudo $PKG_MANAGER install -y containerd.io 2>/dev/null; then
          echo "✅ containerd.io 安装成功"
        else
          echo "⚠️  containerd.io 安装失败，Docker 可能需要手动安装 containerd"
          echo "⚠️  如果 Docker 启动失败，请尝试手动安装 containerd.io"
        fi
        
        echo "✅ Docker 二进制安装成功"
        DOCKER_INSTALL_SUCCESS=true
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
  fi
  
  # 检测 systemd 是否可用：PID 1 须为 systemd 且 dbus 可连通（仅有 /run/systemd 在容器/WSL 中不可靠）
  SYSTEMD_AVAILABLE=false
  if command -v systemctl &>/dev/null; then
    PID1_COMM_KYLIN=$(tr -d '\0' < /proc/1/comm 2>/dev/null || echo "")
    if [[ "$PID1_COMM_KYLIN" == "systemd" ]] && systemctl show-environment &>/dev/null; then
      SYSTEMD_AVAILABLE=true
    fi
  fi
  
  if [[ "$SYSTEMD_AVAILABLE" == "true" ]]; then
    echo "正在启动 Docker 服务..."
    sudo systemctl daemon-reload 2>/dev/null || true
    if sudo systemctl enable docker 2>/dev/null; then
      echo "✅ Docker 服务已启用"
    fi
    if sudo systemctl start docker 2>/dev/null; then
      echo "✅ Docker 服务启动成功"
    else
      echo "⚠️  systemctl 启动失败，尝试手动启动..."
      # 尝试手动启动 dockerd
      if sudo dockerd > /dev/null 2>&1 & then
        sleep 3
        if docker info &>/dev/null; then
          echo "✅ Docker daemon 手动启动成功"
        else
          echo "⚠️  Docker daemon 启动失败，请手动启动: sudo dockerd &"
        fi
      fi
    fi
  else
    echo "⚠️  检测到 systemd 不可用（可能是容器环境）"
    echo "⚠️  将尝试手动启动 Docker daemon..."
    # 创建必要的目录
    sudo mkdir -p /var/run/docker
    sudo mkdir -p /var/lib/docker
    
    # 尝试启动 dockerd
    if sudo dockerd > /tmp/dockerd.log 2>&1 & then
      DOCKERD_PID=$!
      sleep 3
      if docker info &>/dev/null; then
        echo "✅ Docker daemon 手动启动成功 (PID: $DOCKERD_PID)"
        echo "⚠️  注意：Docker daemon 在后台运行，退出终端前请使用 'sudo kill $DOCKERD_PID' 停止"
      else
        echo "⚠️  Docker daemon 启动可能失败，请检查日志: cat /tmp/dockerd.log"
        echo "⚠️  可以尝试手动启动: sudo dockerd &"
      fi
    else
      echo "⚠️  无法自动启动 Docker daemon，请手动执行: sudo dockerd &"
    fi
  fi
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 确定 Docker Compose 架构标识（使用已定义的DOCKER_ARCH变量）
  if [[ "$ARCH" == "x86_64" ]]; then
    COMPOSE_ARCH="x86_64"
  elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    COMPOSE_ARCH="aarch64"
  else
    COMPOSE_ARCH="$DOCKER_ARCH"
  fi
  
  # 临时文件路径
  COMPOSE_TMP="/tmp/docker-compose-$$"
  
  # 源1: 优先使用包管理器安装（最可靠）
  echo "尝试使用包管理器安装 docker-compose-plugin..."
  if sudo $PKG_MANAGER install -y docker-compose-plugin 2>/dev/null; then
    echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
    DOCKER_COMPOSE_DOWNLOADED=true
  else
    echo "⚠️  包管理器安装失败，尝试从国内镜像源下载..."
  fi
  
  # 源2: 使用国内镜像源下载（如果包管理器失败）
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    # 尝试使用 get.docker.com 的镜像（如果有）
    echo "尝试从国内镜像源下载 docker-compose..."
    
    # 使用固定版本 v2.24.0，从国内镜像下载
    # 注意：国内镜像源可能没有最新版本，使用固定版本更可靠
    COMPOSE_VERSION="2.24.0"
    
    # 尝试多个国内镜像源
    # 源2.1: 阿里云镜像（如果有）
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从阿里云镜像下载 docker-compose v${COMPOSE_VERSION}..."
      # 注意：国内镜像源可能没有 docker-compose，这里尝试但不保证成功
      if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/${COMPOSE_VERSION}/docker-compose-Linux-${COMPOSE_ARCH}" -o "$COMPOSE_TMP" --connect-timeout 10 --max-time 60 2>/dev/null; then
        FILE_SIZE=$(stat -f%z "$COMPOSE_TMP" 2>/dev/null || stat -c%s "$COMPOSE_TMP" 2>/dev/null || echo "0")
        if [[ "$FILE_SIZE" -gt 10485760 ]] || (file "$COMPOSE_TMP" 2>/dev/null | grep -q "ELF\|executable\|binary") || (head -c 4 "$COMPOSE_TMP" 2>/dev/null | od -An -tx1 | grep -q "7f 45 4c 46"); then
          sudo mv "$COMPOSE_TMP" /usr/local/bin/docker-compose
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从阿里云镜像下载成功"
        else
          if head -c 20 "$COMPOSE_TMP" 2>/dev/null | grep -q "<!DOCTYPE\|<html"; then
            echo "❌ 下载的文件是 HTML 页面，不是二进制文件"
          fi
          sudo rm -f "$COMPOSE_TMP"
        fi
      fi
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 如果安装的是独立的 docker-compose 二进制文件
    if [[ -f /usr/local/bin/docker-compose ]]; then
      # 设置执行权限
      sudo chmod +x /usr/local/bin/docker-compose
      
      # 创建软链接到 PATH 目录
      sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
      
      echo "✅ Docker Compose 安装完成"
    elif command -v docker &>/dev/null && docker compose version &>/dev/null; then
      echo "✅ Docker Compose Plugin 已安装（使用 'docker compose' 命令）"
    fi
  else
    echo "⚠️  Docker Compose 自动安装失败"
    echo ""
    echo "📋 手动安装方法："
    echo "  方法1: 使用包管理器（推荐）"
    echo "    sudo $PKG_MANAGER install -y docker-compose-plugin"
    echo ""
    echo "  方法2: 手动下载二进制文件"
    echo "    由于 GitHub 在国内访问受限，建议："
    echo "    1. 使用代理或 VPN 访问 GitHub"
    echo "    2. 或从其他可靠源下载 docker-compose 二进制文件"
    echo ""
    echo "  安装后验证："
    echo "    docker compose version  或  docker-compose version"
    echo ""
    echo "  更多信息: https://docs.docker.com/compose/install/"
  fi

elif [[ "$OS" == "almalinux" ]]; then
  # AlmaLinux (CentOS 替代品) 支持
  echo "检测到 AlmaLinux $VERSION_ID"
  echo "AlmaLinux 是 RHEL 的 1:1 二进制兼容克隆，企业级长期支持"
  
  # AlmaLinux 使用 dnf 而不是 yum
  sudo dnf install -y dnf-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，使用 AlmaLinux 兼容的 CentOS 9 版本
  echo "正在创建 Docker 仓库配置 (使用 CentOS 9 兼容源)..."
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo dnf makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/9/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo dnf makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 临时禁用 set -e，允许错误处理
  set +e
  
  echo "正在尝试安装 Docker CE（这可能需要几分钟，请耐心等待）..."
  echo "如果安装过程卡住，可能是网络问题或依赖解析中，请等待..."
  
  # 尝试安装 Docker，使用超时机制（30分钟超时）
  INSTALL_OUTPUT=""
  INSTALL_STATUS=1
  
  # 使用 timeout 命令（如果可用）或直接执行
  # 注意：使用 bash -c 确保 sudo 函数在子 shell 中可用
  if command -v timeout &> /dev/null; then
    INSTALL_OUTPUT=$(timeout 1800 bash -c "sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin" 2>&1)
    INSTALL_STATUS=$?
    if [[ $INSTALL_STATUS -eq 124 ]]; then
      echo "❌ 安装超时（30分钟），可能是网络问题或依赖解析失败"
      INSTALL_STATUS=1
    fi
  else
    INSTALL_OUTPUT=$(sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 2>&1)
    INSTALL_STATUS=$?
  fi
  
  # 重新启用 set -e
  set -e
  
  if [[ $INSTALL_STATUS -eq 0 ]]; then
    echo "✅ Docker CE 安装成功"
  else
    # 显示详细错误信息
    echo ""
    echo "❌ Docker CE 批量安装失败"
    echo "错误详情："
    echo "$INSTALL_OUTPUT" | tail -20
    echo ""
    
    # 检查错误类型
    if echo "$INSTALL_OUTPUT" | grep -qiE "(timeout|timed out|connection|网络|network)"; then
      echo "⚠️  检测到可能的网络问题，请检查网络连接"
    fi
    if echo "$INSTALL_OUTPUT" | grep -qiE "(repo|repository|仓库|not found|找不到)"; then
      echo "⚠️  检测到可能的仓库配置问题，请检查 Docker 源配置"
    fi
    
    echo "正在尝试逐个安装组件..."
    
    # 临时禁用 set -e
    set +e
    
    # 逐个安装组件
    echo "  - 正在安装 containerd.io..."
    CONTAINERD_OUTPUT=$(sudo dnf install -y containerd.io 2>&1)
    CONTAINERD_STATUS=$?
    if [[ $CONTAINERD_STATUS -eq 0 ]]; then
      echo "  ✅ containerd.io 安装成功"
    else
      echo "  ❌ containerd.io 安装失败"
      echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce-cli..."
    DOCKER_CLI_OUTPUT=$(sudo dnf install -y docker-ce-cli 2>&1)
    DOCKER_CLI_STATUS=$?
    if [[ $DOCKER_CLI_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce-cli 安装成功"
    else
      echo "  ❌ docker-ce-cli 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CLI_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce..."
    DOCKER_CE_OUTPUT=$(sudo dnf install -y docker-ce 2>&1)
    DOCKER_CE_STATUS=$?
    if [[ $DOCKER_CE_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce 安装成功"
    else
      echo "  ❌ docker-ce 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-buildx-plugin..."
    BUILDX_OUTPUT=$(sudo dnf install -y docker-buildx-plugin 2>&1)
    BUILDX_STATUS=$?
    if [[ $BUILDX_STATUS -eq 0 ]]; then
      echo "  ✅ docker-buildx-plugin 安装成功"
    else
      echo "  ⚠️  docker-buildx-plugin 安装失败（可选组件，不影响核心功能）"
    fi
    
    # 重新启用 set -e
    set -e
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo ""
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，使用多个备用下载源
  echo "正在下载 Docker Compose..."
  
  # 尝试多个下载源
  DOCKER_COMPOSE_DOWNLOADED=false
  
  # 源1: 阿里云镜像
  echo "尝试从阿里云镜像下载..."
  if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从阿里云镜像下载成功"
  else
    echo "❌ 阿里云镜像下载失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从腾讯云镜像下载..."
    if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从腾讯云镜像下载成功"
    else
      echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从华为云镜像下载..."
    if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从华为云镜像下载成功"
    else
      echo "❌ 华为云镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从中科大镜像下载..."
    if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从中科大镜像下载成功"
    else
      echo "❌ 中科大镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从清华大学镜像下载..."
    if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从清华大学镜像下载成功"
    else
      echo "❌ 清华大学镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从 GitHub 下载..."
    if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从 GitHub 下载成功"
    else
      echo "❌ GitHub 下载失败"
    fi
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if sudo dnf install -y docker-compose-plugin; then
      echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
      DOCKER_COMPOSE_DOWNLOADED=true
    else
      echo "❌ 包管理器安装也失败了"
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi

elif [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" || "$OS" == "deepin" ]]; then
  # 检查 Debian/Ubuntu/Kali/Deepin 版本，为老版本提供兼容性支持
  if [[ ("$OS" == "debian" && ("$VERSION_ID" == "9" || "$VERSION_ID" == "10")) || ("$OS" == "ubuntu" && "$VERSION_ID" == "16.04") ]]; then
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      echo "⚠️  检测到 Debian 9 (Stretch)，使用兼容的安装方法..."
      echo "⚠️  注意：Debian 9 已于 2020年7月停止主线支持，2022年6月停止LTS支持"
      echo "⚠️  建议升级到 Debian 10 (Buster) 或更高版本"
    elif [[ "$OS" == "debian" && "$VERSION_ID" == "10" ]]; then
      echo "⚠️  检测到 Debian 10 (Buster)，使用兼容的安装方法..."
      echo "⚠️  注意：Debian 10 将于 2024年6月停止主线支持，建议考虑升级到 Debian 11+"
    elif [[ "$OS" == "ubuntu" && "$VERSION_ID" == "16.04" ]]; then
      echo "⚠️  检测到 Ubuntu 16.04 (Xenial)，使用兼容的安装方法..."
      echo "⚠️  注意：Ubuntu 16.04 已于 2021 年结束生命周期，将使用特殊处理..."
    fi
    
    # 清理损坏的软件源索引文件
    echo "正在清理损坏的软件源索引文件..."
    sudo rm -rf /var/lib/apt/lists/*
    sudo rm -rf /var/lib/apt/lists/partial/*
    
    # 强制清理 apt 缓存
    sudo apt-get clean
    sudo apt-get autoclean
    
    # 为 Debian 9/10 或 Ubuntu 16.04 配置更兼容的软件源
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      echo "正在配置 Debian 9 兼容的软件源..."
      
      # ⚠️ Debian 9 (Stretch) 生命周期结束警告
      echo ""
      echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
      echo "⚠️  重要提醒：Debian 9 (Stretch) 生命周期已结束"
      echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
      echo "⚠️  📅 2020 年 7 月：停止主线支持（EOL）"
      echo "⚠️  📅 2022 年 6 月：停止 LTS（长期支持）"
      echo "⚠️  "
      echo "⚠️  之后，不再在 deb.debian.org 和 security.debian.org 提供软件包"
      echo "⚠️  建议升级到至少 Debian 10 (Buster) 或更高版本"
      echo "⚠️  "
      echo "⚠️  当前将使用归档源继续安装，但强烈建议尽快升级系统"
      echo "⚠️  ═══════════════════════════════════════════════════════════════════════════════"
      echo ""
      
      # 备份原始源列表
      sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
      
      # Debian 9 已停止支持，使用归档源
      echo "正在配置 Debian 9 归档源（官方源已停止支持）..."
      
      # 使用官方归档源（亲测可用）
      sudo tee /etc/apt/sources.list > /dev/null <<EOF
# Debian 9 (Stretch) 官方归档源 - 主要源
# ⚠️ 注意：Debian 9 已停止支持，建议升级到 Debian 10+ 或更高版本
deb http://archive.debian.org/debian stretch main contrib non-free
deb http://archive.debian.org/debian-security stretch/updates main contrib non-free

# 国内归档镜像源 - 备用源（速度快）
# 阿里云归档源
# deb http://mirrors.aliyun.com/debian-archive/debian stretch main contrib non-free
# deb http://mirrors.aliyun.com/debian-archive/debian-security stretch/updates main contrib non-free

# 清华大学归档源
# deb https://mirrors.tuna.tsinghua.edu.cn/debian-archive/debian stretch main contrib non-free
# deb https://mirrors.tuna.tsinghua.edu.cn/debian-archive/debian-security stretch/updates main contrib non-free
EOF
      
      echo "✅ Debian 9 归档源配置完成"
      echo "💡 建议：安装完成后考虑升级到 Debian 10 (Buster) 或更高版本"
    elif [[ "$VERSION_ID" == "10" ]]; then
      echo "正在配置 Debian 10 兼容的软件源..."
      
      # 备份原始源列表
      sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
      
      # 使用国内镜像源替代 archive.debian.org，提高下载速度
      echo "正在配置国内镜像源以提高下载速度..."
      
      # 尝试配置阿里云镜像源
      sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 阿里云镜像源 - 主要源
deb http://mirrors.aliyun.com/debian/ buster main contrib non-free
deb http://mirrors.aliyun.com/debian-security/ buster/updates main contrib non-free
deb http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free

# 备用源 - 腾讯云镜像
# deb http://mirrors.cloud.tencent.com/debian/ buster main contrib non-free
# deb http://mirrors.cloud.tencent.com/debian-security/ buster/updates main contrib non-free
# deb http://mirrors.cloud.tencent.com/debian/ buster-updates main contrib non-free

# 备用源 - 华为云镜像
# deb http://mirrors.huaweicloud.com/debian/ buster main contrib non-free
# deb http://mirrors.huaweicloud.com/debian-security/ buster/updates main contrib non-free
# deb http://mirrors.huaweicloud.com/debian/ buster-updates main contrib non-free

# 最后备用 - archive.debian.org（如果国内源都不可用）
# deb http://archive.debian.org/debian/ buster main
# deb http://archive.debian.org/debian-security/ buster/updates main
# deb http://archive.debian.org/debian/ buster-updates main
EOF
      
      echo "✅ Debian 10 国内镜像源配置完成"
    elif [[ "$OS" == "ubuntu" && "$VERSION_ID" == "16.04" ]]; then
      echo "正在配置 Ubuntu 16.04 兼容的软件源..."
      echo "⚠️  Ubuntu 16.04 官方支持已结束，建议升级到 Ubuntu 20.04 LTS 或更高版本"
      echo "✅ Ubuntu 16.04 软件源配置保持现状（通常已配置国内镜像源）"
    fi
    
    # 首先尝试安装基本工具
    echo "正在安装基本工具..."
    
    # 测试软件源可用性并自动切换
    echo "正在测试软件源可用性..."
    # Debian 9 需要忽略过期校验
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      if sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false 2>/dev/null; then
        echo "✅ 当前软件源可用"
      else
        echo "⚠️  当前软件源不可用，尝试切换到备用源..."
        
        # 尝试腾讯云镜像源
        DEBIAN_CODENAME="stretch"
        
        sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 腾讯云镜像源
deb http://mirrors.cloud.tencent.com/debian/ ${DEBIAN_CODENAME} main contrib non-free
deb http://mirrors.cloud.tencent.com/debian-security/ ${DEBIAN_CODENAME}/updates main contrib non-free
deb http://mirrors.cloud.tencent.com/debian/ ${DEBIAN_CODENAME}-updates main contrib non-free
EOF
        
        if sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false 2>/dev/null; then
          echo "✅ 腾讯云镜像源可用"
        else
          echo "⚠️  腾讯云镜像源也不可用，尝试华为云镜像源..."
          
          # 尝试华为云镜像源
          sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 华为云镜像源
deb http://mirrors.huaweicloud.com/debian/ ${DEBIAN_CODENAME} main contrib non-free
deb http://mirrors.huaweicloud.com/debian-security/ ${DEBIAN_CODENAME}/updates main contrib non-free
deb http://mirrors.huaweicloud.com/debian/ ${DEBIAN_CODENAME}-updates main contrib non-free
EOF
          
          if sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false 2>/dev/null; then
            echo "✅ 华为云镜像源可用"
          else
            echo "⚠️  所有国内镜像源都不可用，回退到 archive.debian.org..."
            
            # 回退到 archive.debian.org
            sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 官方归档源（速度较慢但稳定）
deb http://archive.debian.org/debian/ ${DEBIAN_CODENAME} main
deb http://archive.debian.org/debian-security/ ${DEBIAN_CODENAME}/updates main
deb http://archive.debian.org/debian/ ${DEBIAN_CODENAME}-updates main
EOF
            
            sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false || true
          fi
        fi
      fi
    else
      if sudo apt-get update --allow-unauthenticated 2>/dev/null; then
        echo "✅ 当前软件源可用"
      else
        echo "⚠️  当前软件源不可用，尝试切换到备用源..."
        
        # 尝试腾讯云镜像源
        if [[ "$OS" == "debian" && "$VERSION_ID" == "10" ]]; then
          DEBIAN_CODENAME="buster"
        else
          DEBIAN_CODENAME="buster"  # 默认使用 buster
        fi
        
        sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 腾讯云镜像源
deb http://mirrors.cloud.tencent.com/debian/ ${DEBIAN_CODENAME} main contrib non-free
deb http://mirrors.cloud.tencent.com/debian-security/ ${DEBIAN_CODENAME}/updates main contrib non-free
deb http://mirrors.cloud.tencent.com/debian/ ${DEBIAN_CODENAME}-updates main contrib non-free
EOF
        
        if sudo apt-get update --allow-unauthenticated 2>/dev/null; then
          echo "✅ 腾讯云镜像源可用"
        else
          echo "⚠️  腾讯云镜像源也不可用，尝试华为云镜像源..."
          
          # 尝试华为云镜像源
          sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 华为云镜像源
deb http://mirrors.huaweicloud.com/debian/ ${DEBIAN_CODENAME} main contrib non-free
deb http://mirrors.huaweicloud.com/debian-security/ ${DEBIAN_CODENAME}/updates main contrib non-free
deb http://mirrors.huaweicloud.com/debian/ ${DEBIAN_CODENAME}-updates main contrib non-free
EOF
          
          if sudo apt-get update --allow-unauthenticated 2>/dev/null; then
            echo "✅ 华为云镜像源可用"
          else
            echo "⚠️  所有国内镜像源都不可用，回退到 archive.debian.org..."
            
            # 回退到 archive.debian.org
            sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 官方归档源（速度较慢但稳定）
deb http://archive.debian.org/debian/ ${DEBIAN_CODENAME} main
deb http://archive.debian.org/debian-security/ ${DEBIAN_CODENAME}/updates main
deb http://archive.debian.org/debian/ ${DEBIAN_CODENAME}-updates main
EOF
            
            sudo apt-get update --allow-unauthenticated || true
          fi
        fi
      fi
    fi
    
    # 尝试安装必要的依赖包
    echo "正在安装必要的依赖包..."
    if sudo apt-get install -y --allow-unauthenticated apt-transport-https ca-certificates gnupg lsb-release; then
      echo "✅ 必要依赖包安装成功"
    else
      echo "⚠️  依赖包安装失败，尝试逐个安装..."
      
      # 逐个安装依赖包
      if sudo apt-get install -y --allow-unauthenticated apt-transport-https; then
        echo "✅ apt-transport-https 安装成功"
      else
        echo "⚠️  apt-transport-https 安装失败"
      fi
      
      if sudo apt-get install -y --allow-unauthenticated ca-certificates; then
        echo "✅ ca-certificates 安装成功"
      else
        echo "⚠️  ca-certificates 安装失败"
      fi
      
      if sudo apt-get install -y --allow-unauthenticated gnupg; then
        echo "✅ gnupg 安装成功"
      else
        echo "⚠️  gnupg 安装失败"
      fi
      
      if sudo apt-get install -y --allow-unauthenticated lsb-release; then
        echo "✅ lsb-release 安装成功"
      else
        echo "⚠️  lsb-release 安装失败"
      fi
    fi
    
    # 尝试安装 dirmngr 和 curl
    if sudo apt-get install -y --allow-unauthenticated dirmngr; then
      echo "✅ dirmngr 安装成功"
    else
      echo "⚠️  dirmngr 安装失败，将使用备用方法"
    fi
    
    if sudo apt-get install -y --allow-unauthenticated curl; then
      echo "✅ curl 安装成功"
    else
      echo "⚠️  curl 安装失败，将使用备用方法"
    fi
    
    # 为 Debian 10 或 Ubuntu 16.04 跳过有问题的包安装，直接使用二进制安装
    if [[ "$VERSION_ID" == "10" || ("$OS" == "ubuntu" && "$VERSION_ID" == "16.04") ]]; then
      if [[ "$OS" == "debian" ]]; then
        echo "⚠️  Debian 10 检测到软件源问题，跳过包管理器安装，直接使用二进制安装..."
      else
        echo "⚠️  Ubuntu 16.04 的 Docker 仓库缺少某些新组件，使用二进制安装..."
      fi
      echo "正在下载 Docker 二进制包..."
      
      # 尝试从多个源下载 Docker 二进制包
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker CE 二进制安装成功"
        
        # 启动 Docker 服务
        echo "正在启动 Docker 服务..."
        sudo systemctl daemon-reload
        sudo systemctl enable docker
        
        # 尝试启动 Docker 服务
        if sudo systemctl start docker; then
          echo "✅ Docker 服务启动成功"
        else
          echo "❌ Docker 服务启动失败，正在诊断问题..."
          
          # 检查服务状态
          echo "Docker 服务状态："
          sudo systemctl status docker --no-pager -l
          
          # 检查日志
          echo "Docker 服务日志："
          sudo journalctl -u docker --no-pager -l --since "5 minutes ago"
          
          # 尝试手动启动 dockerd 进行调试
          echo "尝试手动启动 dockerd 进行调试..."
          sudo /usr/bin/dockerd --debug --log-level=debug &
          DOCKERD_PID=$!
          sleep 5
          
          # 检查 dockerd 是否成功启动
          if sudo kill -0 $DOCKERD_PID 2>/dev/null; then
            echo "✅ dockerd 手动启动成功，问题可能在 systemd 配置"
            sudo kill $DOCKERD_PID
          else
            echo "❌ dockerd 手动启动也失败，请检查系统兼容性"
          fi
          
          echo "故障排除建议："
          echo "1. 检查系统是否支持 Docker"
          echo "2. 检查是否有其他容器运行时冲突"
          echo "3. 检查系统资源是否充足"
          echo "4. 尝试重启系统后再次运行脚本"
          
          exit 1
        fi
        
        # 安装 Docker Compose
        echo ">>> [3.5/8] 安装 Docker Compose..."
        echo "正在下载 Docker Compose..."
        
        # 确定 Docker Compose 架构标识
        if [[ "$ARCH" == "x86_64" ]]; then
          COMPOSE_ARCH="x86_64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
          COMPOSE_ARCH="aarch64"
        else
          COMPOSE_ARCH="$DOCKER_ARCH"
        fi
        
        # 尝试多个下载源
        DOCKER_COMPOSE_DOWNLOADED=false
        
        # 直接使用 GitHub 官方源（最可靠）
        echo "正在从 GitHub 官方源下载 Docker Compose..."
        if sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-linux-${COMPOSE_ARCH}" -o /usr/local/bin/docker-compose --connect-timeout 30 --max-time 120; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从 GitHub 官方源下载成功"
        else
          echo "❌ GitHub 官方源下载失败"
          echo "💡 建议检查网络连接或使用代理"
        fi
        
        if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
          sudo chmod +x /usr/local/bin/docker-compose
          sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
          echo "✅ Docker Compose 安装完成"
        else
          echo "❌ 所有 Docker Compose 下载源都失败"
          echo "💡 建议：可以稍后手动安装 Docker Compose"
          echo "   下载地址：https://github.com/docker/compose/releases"
        fi
        
        # 跳过后续的包管理器安装流程
        echo ">>> [4/8] Docker 安装完成，跳过包管理器安装流程..."
        echo "✅ Docker 已通过二进制方式安装成功"
        echo "✅ Docker Compose 已安装"
        echo "✅ Docker 服务已启动"
        
        # 直接进入镜像配置
        echo ">>> [5/8] 配置轩辕镜像..."
        
        # 循环等待用户选择镜像版本
        while true; do
            echo "请选择版本:"
            echo "1) 轩辕镜像免费版 (域名: docker.xuanyuan.me)"
            echo "2) 轩辕镜像专业版 (专属域名 *.xuanyuan.run / *.xuanyuan.dev 不含免费版域名)"
            echo "3) 恢复/重置镜像相关配置"
            read -p "请输入选择 [1/2/3]: " choice
            
            if [[ "$choice" == "1" || "$choice" == "2" ]]; then
                break
            elif [[ "$choice" == "3" ]]; then
                restore_docker_daemon_config
                exit $?
            else
                echo "❌ 无效选择，请输入 1、2 或 3"
                echo ""
            fi
        done
        
        mirror_list=""
        
        if [[ "$choice" == "2" ]]; then
          read -p "请输入您的轩辕镜像专属域名 (访问官网获取：https://xuanyuan.cloud): " custom_domain

          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_run"
]
EOF
)
          else
            mirror_list=$(cat <<EOF
[
  "https://$custom_domain"
]
EOF
)
          fi
        else
          mirror_list=$(cat <<EOF
[
  "https://docker.xuanyuan.me"
]
EOF
)
        fi

        mkdir -p /etc/docker

        # 根据用户选择设置 insecure-registries
        if [[ "$choice" == "2" ]]; then
          # 清理用户输入的域名，移除协议前缀
          custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
          
          # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
          if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_dev"
]
EOF
)
          elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_run"
]
EOF
)
          else
            insecure_registries=$(cat <<EOF
[
  "$custom_domain"
]
EOF
)
          fi
        else
          insecure_registries=$(cat <<EOF
[
  "docker.xuanyuan.me"
]
EOF
)
        fi

        # 准备 DNS 配置字符串
dns_config=""
if [[ "$SKIP_DNS" != "true" ]]; then
  if ! grep -q "nameserver" /etc/resolv.conf; then
     dns_config=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
  else
     echo "ℹ️  检测到系统已配置 DNS，跳过 Docker DNS 配置以避免冲突"
  fi
fi

cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_config
}
EOF
        
        sudo systemctl daemon-reexec || true
        sudo systemctl restart docker || true
        
        echo ">>> [6/8] 安装完成！"
        echo "🎉Docker 镜像已配置完成"
        echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
        echo "官方网站: https://xuanyuan.cloud/"
        
        # 显示当前配置的镜像源
        echo ""
        echo "当前配置的镜像源："
        if [[ "$choice" == "2" ]]; then
            if [[ "$custom_domain" == *.xuanyuan.run ]]; then
                custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_dev (备用)"
            elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
                custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
                echo "  - https://$custom_domain (优先)"
                echo "  - https://$custom_domain_run (备用)"
            else
                echo "  - https://$custom_domain"
            fi
        else
            echo "  - https://docker.xuanyuan.me"
        fi
        echo ""
        
        echo "🎉 安装和配置完成！"
        echo ""
        echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
        echo "官方网站: https://xuanyuan.cloud/"
        exit 0
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
    
    # 如果 curl 安装失败，尝试使用 wget 作为备用
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
      echo "正在安装 wget 作为 curl 的备用..."
      apt-get install -y --allow-unauthenticated wget || true
    fi
    
    # 现在尝试更新过期的 GPG 密钥
    echo "正在更新过期的 GPG 密钥..."
    if command -v dirmngr &> /dev/null; then
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 || true
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 || true
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 || true
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A || true
      
      # 尝试使用不同的密钥服务器
      echo "尝试使用备用密钥服务器..."
      apt-key adv --keyserver pgpkeys.mit.edu --recv-keys 648ACFD622F3D138 || true
      apt-key adv --keyserver pgpkeys.mit.edu --recv-keys 0E98404D386FA1D9 || true
    else
      echo "⚠️  dirmngr 不可用，跳过 GPG 密钥更新"
    fi
    
    
    # 更新软件包列表，允许未认证的包，移除不支持的选项
    echo "正在更新软件包列表..."
    # Debian 9 需要忽略过期校验
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false || true
    else
      sudo apt-get update --allow-unauthenticated || true
    fi
    
    # 如果还是失败，尝试强制更新
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      if ! sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false; then
        echo "⚠️  软件源更新失败，尝试强制更新..."
        sudo apt-get update --allow-unauthenticated --fix-missing -o Acquire::Check-Valid-Until=false || true
      fi
    else
      if ! sudo apt-get update --allow-unauthenticated; then
        echo "⚠️  软件源更新失败，尝试强制更新..."
        sudo apt-get update --allow-unauthenticated --fix-missing || true
      fi
    fi
    
    # 安装必要的依赖包，允许未认证的包
    echo "正在安装必要的依赖包..."
    sudo apt-get install -y --allow-unauthenticated --fix-broken ca-certificates gnupg lsb-release apt-transport-https || true
    
    # 如果某些包安装失败，尝试逐个安装
    if ! dpkg -l | grep -q "ca-certificates"; then
      echo "尝试单独安装 ca-certificates..."
      sudo apt-get install -y --allow-unauthenticated ca-certificates || true
    fi
    
    if ! dpkg -l | grep -q "gnupg"; then
      echo "尝试单独安装 gnupg..."
      sudo apt-get install -y --allow-unauthenticated gnupg || true
    fi
    
    # 添加 Docker 官方 GPG 密钥
    echo "正在添加 Docker 官方 GPG 密钥..."
    if command -v curl &> /dev/null; then
      # 尝试从国内镜像下载 GPG 密钥
      if sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从阿里云镜像下载 Docker GPG 密钥成功"
      elif sudo curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从腾讯云镜像下载 Docker GPG 密钥成功"
      elif sudo curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从华为云镜像下载 Docker GPG 密钥成功"
      else
        echo "❌ 所有国内镜像都无法下载 Docker GPG 密钥"
      fi
    elif command -v wget &> /dev/null; then
      # 尝试从国内镜像下载 GPG 密钥
      if sudo wget -qO- https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从阿里云镜像下载 Docker GPG 密钥成功"
      elif sudo wget -qO- https://mirrors.cloud.tencent.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从腾讯云镜像下载 Docker GPG 密钥成功"
      elif sudo wget -qO- https://mirrors.huaweicloud.com/docker-ce/linux/debian/gpg | sudo apt-key add -; then
        echo "✅ 从华为云镜像下载 Docker GPG 密钥成功"
      else
        echo "❌ 所有国内镜像都无法下载 Docker GPG 密钥"
      fi
    else
      echo "❌ 无法下载 Docker GPG 密钥，curl 和 wget 都不可用"
    fi
    
    # 添加 Docker 仓库（使用国内镜像源）
    echo "正在添加 Docker 仓库..."
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      DEBIAN_CODENAME="stretch"
    elif [[ "$OS" == "debian" && "$VERSION_ID" == "10" ]]; then
      DEBIAN_CODENAME="buster"
    else
      DEBIAN_CODENAME="stretch"  # 默认使用 stretch
    fi
    
    # 尝试配置国内 Docker 镜像源
    echo "deb [arch=$(dpkg --print-architecture)] https://mirrors.aliyun.com/docker-ce/linux/debian ${DEBIAN_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 再次更新，这次包含 Docker 仓库
    echo "正在更新包含 Docker 仓库的软件包列表..."
    # Debian 9 需要忽略过期校验
    if [[ "$OS" == "debian" && "$VERSION_ID" == "9" ]]; then
      sudo apt-get update --allow-unauthenticated -o Acquire::Check-Valid-Until=false || true
    else
      sudo apt-get update --allow-unauthenticated || true
    fi
    
    echo ">>> [3/8] 安装 Docker CE 兼容版本..."
    echo "正在安装 Docker CE..."
    sudo apt-get install -y --allow-unauthenticated --fix-broken docker-ce docker-ce-cli containerd.io || true
    
    # 检查 Docker 是否安装成功
    if command -v docker &> /dev/null; then
      echo "✅ Docker CE 安装成功"
    else
      echo "❌ Docker CE 安装失败，尝试备用方法..."
      # 尝试从多个源下载 Docker 二进制包
      echo "正在下载 Docker 二进制包..."
      DOCKER_BINARY_DOWNLOADED=false
      
      if command -v curl &> /dev/null; then
        # 源1: 阿里云镜像
        echo "尝试从阿里云镜像下载 Docker 二进制包..."
        if sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从阿里云镜像下载成功"
        else
          echo "❌ 阿里云镜像下载失败，尝试下一个源..."
        fi
        
        # 源2: 腾讯云镜像
        if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
          echo "尝试从腾讯云镜像下载 Docker 二进制包..."
          if sudo curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
            DOCKER_BINARY_DOWNLOADED=true
            echo "✅ 从腾讯云镜像下载成功"
          else
            echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
          fi
        fi
        
        # 源3: 华为云镜像
        if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
          echo "尝试从华为云镜像下载 Docker 二进制包..."
          if sudo curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
            DOCKER_BINARY_DOWNLOADED=true
            echo "✅ 从华为云镜像下载成功"
          else
            echo "❌ 华为云镜像下载失败"
          fi
        fi
      elif command -v wget &> /dev/null; then
        # 源1: 阿里云镜像
        echo "尝试从阿里云镜像下载 Docker 二进制包..."
        if sudo wget -O /tmp/docker.tgz https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz --timeout=60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从阿里云镜像下载成功"
        else
          echo "❌ 阿里云镜像下载失败，尝试下一个源..."
        fi
        
        # 源2: 腾讯云镜像
        if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
          echo "尝试从腾讯云镜像下载 Docker 二进制包..."
          if sudo wget -O /tmp/docker.tgz https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz --timeout=60; then
            DOCKER_BINARY_DOWNLOADED=true
            echo "✅ 从腾讯云镜像下载成功"
          else
            echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
          fi
        fi
        
        # 源3: 华为云镜像
        if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
          echo "尝试从华为云镜像下载 Docker 二进制包..."
          if sudo wget -O /tmp/docker.tgz https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz --timeout=60; then
            DOCKER_BINARY_DOWNLOADED=true
            echo "✅ 从华为云镜像下载成功"
          else
            echo "❌ 华为云镜像下载失败"
          fi
        fi
      else
        echo "❌ 无法下载 Docker 二进制包，curl 和 wget 都不可用"
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" && -f /tmp/docker.tgz ]]; then
        echo "正在解压 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /tmp
        sudo cp /tmp/docker/* /usr/bin/
        sudo chmod +x /usr/bin/docker*
        echo "✅ Docker CE 二进制安装成功"
      else
        echo "❌ Docker 二进制下载失败"
      fi
    fi
    
    echo ">>> [3.5/8] 安装 Docker Compose 兼容版本..."
    # Debian 9 使用较老版本的 docker-compose
    echo "正在下载兼容的 Docker Compose..."
    
    # 确定 Docker Compose 架构标识
    if [[ "$ARCH" == "x86_64" ]]; then
      COMPOSE_ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
      COMPOSE_ARCH="aarch64"
    else
      COMPOSE_ARCH="$DOCKER_ARCH"
    fi
    
    DOCKER_COMPOSE_DOWNLOADED=false
    
    # 尝试从多个源下载兼容版本
    echo "正在尝试从多个源下载 Docker Compose 兼容版本..."
    
    # 源1: 阿里云镜像
    if command -v curl &> /dev/null; then
      echo "尝试从阿里云镜像下载兼容版本..."
      if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.25.5/docker-compose-linux-${COMPOSE_ARCH}" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载兼容版本成功"
      fi
    elif command -v wget &> /dev/null; then
      echo "尝试从阿里云镜像下载兼容版本..."
      if sudo wget -O /usr/local/bin/docker-compose "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.25.5/docker-compose-linux-${COMPOSE_ARCH}" --timeout=30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载兼容版本成功"
      fi
    fi
    
    # 源2: 腾讯云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      if command -v curl &> /dev/null; then
        echo "尝试从腾讯云镜像下载兼容版本..."
        if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.25.5/docker-compose-linux-${COMPOSE_ARCH}" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载兼容版本成功"
        fi
      elif command -v wget &> /dev/null; then
        echo "尝试从腾讯云镜像下载兼容版本..."
        if sudo wget -O /usr/local/bin/docker-compose "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.25.5/docker-compose-linux-${COMPOSE_ARCH}" --timeout=30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载兼容版本成功"
        fi
      fi
    fi
    
    # 源3: 华为云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      if command -v curl &> /dev/null; then
        echo "尝试从华为云镜像下载兼容版本..."
        if curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从华为云镜像下载兼容版本成功"
        fi
      elif command -v wget &> /dev/null; then
        echo "尝试从华为云镜像下载兼容版本..."
        if sudo wget -O /usr/local/bin/docker-compose "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.25.5/docker-compose-$(uname -s)-$(uname -m)" --timeout=30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从华为云镜像下载兼容版本成功"
        fi
      fi
    fi
    
    # 源4: 最后尝试 GitHub
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      if command -v curl &> /dev/null; then
        echo "尝试从 GitHub 下载兼容版本..."
        if sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从 GitHub 下载兼容版本成功"
        fi
      elif command -v wget &> /dev/null; then
        echo "尝试从 GitHub 下载兼容版本..."
        if sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" --timeout=30; then
          DOCKER_COMPOSE_DOWNLOADED=true
          echo "✅ 从 GitHub 下载兼容版本成功"
        fi
      fi
    fi
    
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "❌ GitHub 下载失败，尝试包管理器安装..."
      if sudo apt-get install -y --allow-unauthenticated docker-compose; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 通过包管理器安装 docker-compose 成功"
      else
        echo "❌ 包管理器安装也失败了"
      fi
    fi
    
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
      sudo chmod +x /usr/local/bin/docker-compose
      sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
      echo "✅ Docker Compose 兼容版本安装完成"
    else
      echo "❌ Docker Compose 安装失败"
    fi
    
  else
    # 现代版本的 Ubuntu/Debian/Kali 使用标准安装方法
    sudo apt-get update
    
    # 安装必要的依赖包，添加错误处理和容错机制
    echo "正在安装必要的依赖包..."
    if sudo apt-get install -y --fix-missing ca-certificates curl gnupg lsb-release; then
      echo "✅ 必要依赖包安装成功"
    else
      echo "⚠️  批量安装失败，尝试逐个安装..."
      
      # 逐个安装依赖包
      if sudo apt-get install -y --fix-missing ca-certificates; then
        echo "✅ ca-certificates 安装成功"
      else
        echo "⚠️  ca-certificates 安装失败，将尝试继续..."
      fi
      
      if sudo apt-get install -y --fix-missing curl; then
        echo "✅ curl 安装成功"
      else
        echo "⚠️  curl 安装失败，将尝试继续..."
      fi
      
      if sudo apt-get install -y --fix-missing gnupg; then
        echo "✅ gnupg 安装成功"
      else
        echo "⚠️  gnupg 安装失败，将尝试继续..."
      fi
      
      if sudo apt-get install -y --fix-missing lsb-release; then
        echo "✅ lsb-release 安装成功"
      else
        echo "⚠️  lsb-release 安装失败，将尝试继续..."
      fi
      
      # 检查关键工具是否安装成功
      if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo "⚠️  curl 和 wget 都未安装，某些功能可能受限..."
      fi
      
      if ! command -v gpg &> /dev/null; then
        echo "⚠️  gpg 未安装，某些功能可能受限..."
      fi
      
      if ! command -v lsb_release &> /dev/null; then
        echo "⚠️  lsb-release 未安装，将使用备用方法检测系统版本..."
        # 如果 lsb-release 未安装，使用 /etc/os-release 作为备用
        if [[ -f /etc/os-release ]]; then
          DEBIAN_CODENAME_BACKUP=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"' 2>/dev/null || echo "")
        fi
      fi
    fi

    # Kali Linux 需要使用 Debian 仓库
    DOCKER_OS="$OS"
    # 如果 lsb-release 安装成功，使用它；否则使用备用方法
    if command -v lsb_release &> /dev/null; then
      DEBIAN_CODENAME=$(lsb_release -cs)
    elif [[ -n "$DEBIAN_CODENAME_BACKUP" ]]; then
      DEBIAN_CODENAME="$DEBIAN_CODENAME_BACKUP"
      echo "⚠️  使用备用方法检测到系统代号: $DEBIAN_CODENAME"
    else
      # 最后的备用方法
      DEBIAN_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"' 2>/dev/null || echo "bookworm")
      echo "⚠️  使用 /etc/os-release 检测到系统代号: $DEBIAN_CODENAME"
    fi
    
    # 检测 Debian Testing/Unstable 并映射到稳定版本
    if [[ "$OS" == "debian" ]]; then
      # 检查是否为 Debian Testing/Unstable（代号可能是 forky、trixie、sid 等）
      VERSION_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"' 2>/dev/null || echo "")
      
      # Debian Testing 的常见代号：forky（当前）、trixie（未来）
      # Debian Unstable 的代号：sid（固定）
      # Docker 官方仓库不支持 Testing/Unstable 版本，需要映射到对应的稳定版本
      if [[ "$DEBIAN_CODENAME" == "forky" ]] || [[ "$VERSION_CODENAME" == "forky" ]] || \
         [[ "$DEBIAN_CODENAME" == "trixie" ]] || [[ "$VERSION_CODENAME" == "trixie" ]] || \
         [[ "$DEBIAN_CODENAME" == "sid" ]] || [[ "$VERSION_CODENAME" == "sid" ]] || \
         [[ -n "$VERSION_CODENAME" && ("$VERSION_CODENAME" == "testing" || "$VERSION_CODENAME" == "unstable") ]]; then
        echo "⚠️  检测到 Debian Testing/Unstable (codename: $DEBIAN_CODENAME)"
        echo "⚠️  Docker 官方仓库不支持 Testing/Unstable 版本，将使用 Debian 12 (bookworm) 仓库"
        DEBIAN_CODENAME="bookworm"
      fi
    fi
    
    if [[ "$OS" == "kali" ]]; then
      DOCKER_OS="debian"
      # Kali Rolling 基于 Debian Testing，使用 bookworm 作为稳定版本
      # 根据 Kali 版本映射到对应的 Debian 代号
      case "$DEBIAN_CODENAME" in
        kali-rolling|kali-dev)
          DEBIAN_CODENAME="bookworm"
          ;;
        *)
          # 其他情况默认使用 bookworm
          DEBIAN_CODENAME="bookworm"
          ;;
      esac
      echo "⚠️  Kali Linux 将使用 Debian Docker 仓库 (codename: $DEBIAN_CODENAME)"
    fi

    if [[ "$OS" == "deepin" ]]; then
      DOCKER_OS="debian"
      DEEPIN_ORIG_CODENAME="$DEBIAN_CODENAME"
      # Docker 无 linux/deepin；Deepin 自有代号（如 crimson、beige）需映射到 Debian stable suite
      case "$DEBIAN_CODENAME" in
        crimson|beige|nymph|martian)
          DEBIAN_CODENAME="bookworm"
          ;;
        apricot|eagle)
          DEBIAN_CODENAME="bullseye"
          ;;
        *)
          if [[ -n "$DEBIAN_CODENAME" ]]; then
            echo "⚠️  Deepin 代号 $DEBIAN_CODENAME 未在映射表，默认使用 bookworm Docker 源（若失败请反馈）"
          fi
          DEBIAN_CODENAME="bookworm"
          ;;
      esac
      echo "ℹ️  Deepin $VERSION_ID（${DEEPIN_ORIG_CODENAME:-unknown}）→ Docker 使用 debian/$DEBIAN_CODENAME"
    fi
    
    # 检测 Ubuntu 版本并处理
    if [[ "$OS" == "ubuntu" ]]; then
      VERSION_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"' 2>/dev/null || echo "")
      ORIGINAL_CODENAME="$DEBIAN_CODENAME"
      
      # Ubuntu LTS 版本（Docker 官方支持）：bionic (18.04), focal (20.04), jammy (22.04), noble (24.04)
      # Ubuntu 非 LTS 版本：plucky (25.04) 等，Docker 官方可能支持也可能不支持
      case "$DEBIAN_CODENAME" in
        bionic|focal|jammy|noble)
          # 这些是支持的 LTS 版本，保持原样
          ;;
        plucky)
          # Ubuntu 25.04 (Plucky Puffin) - 2025年4月发布的非LTS版本
          # Docker 官方可能尚未完全支持，先尝试使用 plucky，失败后会自动回退到 noble
          echo "ℹ️  检测到 Ubuntu 25.04 (Plucky Puffin)"
          echo "ℹ️  将首先尝试使用 Ubuntu 25.04 仓库，如果失败将回退到 Ubuntu 24.04 LTS (noble)"
          # 先保持 plucky，让脚本尝试，失败时会自动回退
          ;;
        warty|hoary|breezy|dapper|edgy|feisty|gutsy|hardy|intrepid|jaunty|karmic|lucid|maverick|natty|oneiric|precise|quantal|raring|saucy|trusty|utopic|vivid|wily|xenial|yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish|kinetic|lunar|mantic)
          # 这些都是很旧的版本或过期的版本，直接映射到最新的 LTS 版本 noble (24.04)
          echo "⚠️  检测到 Ubuntu 旧版本 (codename: $DEBIAN_CODENAME)"
          echo "⚠️  Docker 官方仓库不支持此版本，将使用 Ubuntu 24.04 LTS (noble) 仓库"
          DEBIAN_CODENAME="noble"
          ;;
        "")
          # 无法检测到版本代号，使用最新的 LTS
          echo "⚠️  无法检测 Ubuntu 版本代号，将使用 Ubuntu 24.04 LTS (noble)"
          DEBIAN_CODENAME="noble"
          ;;
        *)
          # 未知的新版本，先尝试使用自身，失败后会回退
          echo "ℹ️  检测到 Ubuntu 新版本 (codename: $DEBIAN_CODENAME)"
          echo "ℹ️  将首先尝试使用此版本的仓库，如果失败将回退到 Ubuntu 24.04 LTS (noble)"
          ;;
      esac
    fi

    sudo install -m 0755 -d /etc/apt/keyrings
    
    # 清理可能存在的旧配置
    sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
    
    # GPG 密钥下载和验证辅助函数
    download_and_verify_gpg_key() {
      local gpg_url=$1
      local key_file="/etc/apt/keyrings/docker.gpg"
      local error_output="/tmp/docker_gpg_error.log"
      
      # 下载并处理 GPG 密钥
      if curl -fsSL "$gpg_url" 2>"$error_output" | sudo gpg --dearmor -o "$key_file" 2>"$error_output"; then
        # 验证密钥文件是否存在且大小合理（应该大于 1000 字节）
        if [[ -f "$key_file" ]] && [[ $(stat -f%z "$key_file" 2>/dev/null || stat -c%s "$key_file" 2>/dev/null || echo 0) -gt 1000 ]]; then
          # 设置正确的权限
          sudo chmod 644 "$key_file" 2>/dev/null || true
          rm -f "$error_output" 2>/dev/null
          return 0
        else
          echo "⚠️  GPG 密钥文件大小异常或不存在"
          rm -f "$key_file" "$error_output" 2>/dev/null
          return 1
        fi
      else
        if [[ -f "$error_output" ]]; then
          echo "⚠️  GPG 密钥下载/处理失败: $(cat "$error_output" 2>/dev/null | head -1)"
          rm -f "$error_output" 2>/dev/null
        fi
        rm -f "$key_file" 2>/dev/null
        return 1
      fi
    }
    
    # 尝试多个国内镜像源配置 Docker 仓库
    echo "正在配置 Docker 源..."
    DOCKER_REPO_ADDED=false
    
    # 源1: 阿里云镜像
    echo "尝试配置阿里云 Docker 源..."
    sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
    if download_and_verify_gpg_key "https://mirrors.aliyun.com/docker-ce/linux/$DOCKER_OS/gpg"; then
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/$DOCKER_OS \
        $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
      # 捕获 apt-get update 的详细错误信息
      update_output="/tmp/docker_apt_update.log"
      if sudo apt-get update >"$update_output" 2>&1; then
        DOCKER_REPO_ADDED=true
        echo "✅ 阿里云 Docker 源配置成功"
        rm -f "$update_output" 2>/dev/null
      else
        echo "❌ 阿里云 Docker 源配置失败"
        if [[ -f "$update_output" ]]; then
          # 显示关键错误信息
          if grep -q "NO_PUBKEY\|GPG error\|NO_PUBKEY" "$update_output" 2>/dev/null; then
            echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
          fi
          rm -f "$update_output" 2>/dev/null
        fi
        echo "   尝试下一个源..."
      fi
    else
      echo "❌ 阿里云 Docker GPG 密钥下载失败，尝试下一个源..."
    fi
    
    # 源2: 腾讯云镜像（使用正确的域名）
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "尝试配置腾讯云 Docker 源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://mirrors.cloud.tencent.com/docker-ce/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.cloud.tencent.com/docker-ce/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 腾讯云 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 腾讯云 Docker 源配置失败"
          if [[ -f "$update_output" ]]; then
            if grep -q "NO_PUBKEY\|GPG error" "$update_output" 2>/dev/null; then
              echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
            fi
            rm -f "$update_output" 2>/dev/null
          fi
          echo "   尝试下一个源..."
        fi
      else
        echo "❌ 腾讯云 Docker GPG 密钥下载失败，尝试下一个源..."
      fi
    fi
    
    # 源3: 华为云镜像
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "尝试配置华为云 Docker 源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://mirrors.huaweicloud.com/docker-ce/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 华为云 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 华为云 Docker 源配置失败"
          if [[ -f "$update_output" ]]; then
            if grep -q "NO_PUBKEY\|GPG error" "$update_output" 2>/dev/null; then
              echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
            fi
            rm -f "$update_output" 2>/dev/null
          fi
          echo "   尝试下一个源..."
        fi
      else
        echo "❌ 华为云 Docker GPG 密钥下载失败，尝试下一个源..."
      fi
    fi
    
    # 源4: 中科大镜像
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "尝试配置中科大 Docker 源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://mirrors.ustc.edu.cn/docker-ce/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.ustc.edu.cn/docker-ce/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 中科大 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 中科大 Docker 源配置失败"
          if [[ -f "$update_output" ]]; then
            if grep -q "NO_PUBKEY\|GPG error" "$update_output" 2>/dev/null; then
              echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
              # 如果是 NO_PUBKEY 错误，显示缺失的密钥 ID
              if grep -q "NO_PUBKEY" "$update_output" 2>/dev/null; then
                missing_key=$(grep -oP "NO_PUBKEY \K[0-9A-F]{16}" "$update_output" | head -1)
                if [[ -n "$missing_key" ]]; then
                  echo "   缺失的 GPG 密钥 ID: $missing_key"
                  echo "   尝试手动添加密钥..."
                  # 尝试从 keyserver 获取密钥
                  if command -v gpg &>/dev/null && command -v apt-key &>/dev/null 2>/dev/null; then
                    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$missing_key" 2>/dev/null || \
                    sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys "$missing_key" 2>/dev/null || true
                  fi
                fi
              fi
            fi
            rm -f "$update_output" 2>/dev/null
          fi
          echo "   尝试下一个源..."
        fi
      else
        echo "❌ 中科大 Docker GPG 密钥下载失败，尝试下一个源..."
      fi
    fi
    
    # 源5: 清华大学镜像
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "尝试配置清华大学 Docker 源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 清华大学 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 清华大学 Docker 源配置失败"
          if [[ -f "$update_output" ]]; then
            if grep -q "NO_PUBKEY\|GPG error" "$update_output" 2>/dev/null; then
              echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
            fi
            rm -f "$update_output" 2>/dev/null
          fi
          echo "   尝试下一个源..."
        fi
      else
        echo "❌ 清华大学 Docker GPG 密钥下载失败，尝试下一个源..."
      fi
    fi
    
    # 源6: 网易镜像
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "尝试配置网易 Docker 源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://mirrors.163.com/docker-ce/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.163.com/docker-ce/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 网易 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 网易 Docker 源配置失败"
          if [[ -f "$update_output" ]]; then
            if grep -q "NO_PUBKEY\|GPG error" "$update_output" 2>/dev/null; then
              echo "   错误详情: $(grep -i "NO_PUBKEY\|GPG error" "$update_output" | head -1)"
            fi
            rm -f "$update_output" 2>/dev/null
          fi
          echo "   尝试下一个源..."
        fi
      else
        echo "❌ 网易 Docker GPG 密钥下载失败，尝试下一个源..."
      fi
    fi
    
    # 如果所有国内源都失败，尝试官方源
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "所有国内源都失败，尝试官方源..."
      sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
      if download_and_verify_gpg_key "https://download.docker.com/linux/$DOCKER_OS/gpg"; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS \
          $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        update_output="/tmp/docker_apt_update.log"
        if sudo apt-get update >"$update_output" 2>&1; then
          DOCKER_REPO_ADDED=true
          echo "✅ 官方 Docker 源配置成功"
          rm -f "$update_output" 2>/dev/null
        else
          echo "❌ 官方 Docker 源也配置失败"
          if [[ -f "$update_output" ]]; then
            echo "   最后尝试的错误信息:"
            grep -i "NO_PUBKEY\|GPG error\|404\|Not Found" "$update_output" 2>/dev/null | head -3
            rm -f "$update_output" 2>/dev/null
          fi
        fi
      else
        echo "❌ 官方 Docker GPG 密钥下载失败"
      fi
    fi
    
    # 如果所有源都失败，且使用的是 Ubuntu 新版本（如 plucky），尝试回退到 LTS 版本
    if [[ "$DOCKER_REPO_ADDED" == "false" ]] && [[ "$OS" == "ubuntu" ]]; then
      # 检查原始版本代号，判断是否需要回退
      if [[ "$ORIGINAL_CODENAME" == "plucky" ]] || [[ "$DEBIAN_CODENAME" == "plucky" ]]; then
        # Ubuntu 25.04 (Plucky Puffin) 配置失败，回退到 Ubuntu 24.04 LTS (noble)
        echo "⚠️  Ubuntu 25.04 (Plucky Puffin) 源配置失败，回退到 Ubuntu 24.04 LTS (noble)..."
        DEBIAN_CODENAME="noble"
        sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
        
        # 再次尝试官方源（最可靠）
        if download_and_verify_gpg_key "https://download.docker.com/linux/$DOCKER_OS/gpg"; then
          echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS \
            $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          
          update_output="/tmp/docker_apt_update.log"
          if sudo apt-get update >"$update_output" 2>&1; then
            DOCKER_REPO_ADDED=true
            echo "✅ 使用 Ubuntu 24.04 LTS (noble) 源配置成功"
            rm -f "$update_output" 2>/dev/null
          else
            rm -f "$update_output" 2>/dev/null
          fi
        fi
      elif [[ "$DEBIAN_CODENAME" == "noble" ]] && [[ "$ORIGINAL_CODENAME" != "noble" ]]; then
        # 如果已经是 noble 但原始不是 noble，说明已经回退过了，再回退到 jammy
        echo "⚠️  Ubuntu 24.04 LTS (noble) 源配置失败，尝试回退到 Ubuntu 22.04 LTS (jammy)..."
        DEBIAN_CODENAME="jammy"
        sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
        
        # 再次尝试官方源（最可靠）
        if download_and_verify_gpg_key "https://download.docker.com/linux/$DOCKER_OS/gpg"; then
          echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS \
            $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          
          update_output="/tmp/docker_apt_update.log"
          if sudo apt-get update >"$update_output" 2>&1; then
            DOCKER_REPO_ADDED=true
            echo "✅ 使用 Ubuntu 22.04 LTS (jammy) 源配置成功"
            rm -f "$update_output" 2>/dev/null
          else
            rm -f "$update_output" 2>/dev/null
          fi
        fi
      elif [[ -n "$ORIGINAL_CODENAME" ]] && [[ "$DEBIAN_CODENAME" != "$ORIGINAL_CODENAME" ]]; then
        # 其他新版本，尝试回退到 noble
        echo "⚠️  Ubuntu $ORIGINAL_CODENAME 源配置失败，尝试回退到 Ubuntu 24.04 LTS (noble)..."
        DEBIAN_CODENAME="noble"
        sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list 2>/dev/null
        
        if download_and_verify_gpg_key "https://download.docker.com/linux/$DOCKER_OS/gpg"; then
          echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS \
            $DEBIAN_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          
          update_output="/tmp/docker_apt_update.log"
          if sudo apt-get update >"$update_output" 2>&1; then
            DOCKER_REPO_ADDED=true
            echo "✅ 使用 Ubuntu 24.04 LTS (noble) 源配置成功"
            rm -f "$update_output" 2>/dev/null
          else
            rm -f "$update_output" 2>/dev/null
          fi
        fi
      fi
    fi
    
    if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
      echo "❌ 所有 Docker 源都配置失败，无法继续安装"
      echo ""
      echo "可能的原因："
      echo "  1. 网络连接问题"
      echo "  2. Ubuntu 版本太新，Docker 官方仓库暂不支持"
      echo "  3. GPG 密钥验证失败"
      echo ""
      echo "建议解决方案："
      echo "  1. 检查网络连接"
      echo "  2. 手动添加 Docker GPG 密钥："
      echo "     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
      echo "  3. 手动配置 Docker 源："
      echo "     echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list"
      echo "  4. 更新软件包列表："
      echo "     sudo apt-get update"
      exit 1
    fi

    echo ">>> [3/8] 安装 Docker CE 最新版..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    echo ">>> [3.5/8] 安装 Docker Compose..."
    # 安装最新版本的 docker-compose，使用多个备用下载源
    echo "正在下载 Docker Compose..."
    
    # 尝试多个下载源
    DOCKER_COMPOSE_DOWNLOADED=false
    
    # 源1: 阿里云镜像
    echo "尝试从阿里云镜像下载..."
    if sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从阿里云镜像下载成功"
    else
      echo "❌ 阿里云镜像下载失败，尝试下一个源..."
    fi
    
    # 源2: 腾讯云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从腾讯云镜像下载..."
      if sudo curl -L "https://mirrors.cloud.tencent.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从腾讯云镜像下载成功"
      else
        echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源3: 华为云镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从华为云镜像下载..."
      if sudo curl -L "https://mirrors.huaweicloud.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从华为云镜像下载成功"
      else
        echo "❌ 华为云镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源4: 中科大镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从中科大镜像下载..."
      if sudo curl -L "https://mirrors.ustc.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从中科大镜像下载成功"
      else
        echo "❌ 中科大镜像下载失败，尝试下一个源..."
      fi
    fi
    
    # 源5: 清华大学镜像
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从清华大学镜像下载..."
      if sudo curl -L "https://mirrors.tuna.tsinghua.edu.cn/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从清华大学镜像下载成功"
      else
        echo "❌ 清华大学镜像下载失败，尝试下一个源..."
      fi
    fi
    
  # 源6: 网易镜像
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "尝试从网易镜像下载..."
    if sudo curl -L "https://mirrors.163.com/docker-toolbox/linux/compose/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
      DOCKER_COMPOSE_DOWNLOADED=true
      echo "✅ 从网易镜像下载成功"
    else
      echo "❌ 网易镜像下载失败，尝试下一个源..."
    fi
  fi
  
  # 源7: 最后尝试 GitHub (如果网络允许)
    # 源7: 最后尝试 GitHub (如果网络允许)
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "尝试从 GitHub 下载..."
      if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 30; then
        DOCKER_COMPOSE_DOWNLOADED=true
        echo "✅ 从 GitHub 下载成功"
      else
        echo "❌ GitHub 下载失败"
      fi
    fi
    
    # 检查是否下载成功
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
      echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
      
      # 使用包管理器作为备选方案
      if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" || "$OS" == "deepin" ]]; then
        if sudo apt-get install -y docker-compose-plugin; then
          echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
          DOCKER_COMPOSE_DOWNLOADED=true
        else
          echo "❌ 包管理器安装也失败了"
        fi
      elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "ol" || "$OS" == "kylin" || "$OS" == "uos" || "$OS" == "uniontechos" ]]; then
        if sudo yum install -y docker-compose-plugin; then
          echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
          DOCKER_COMPOSE_DOWNLOADED=true
        else
          echo "❌ 包管理器安装也失败了"
        fi
      fi
    fi
    
    if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
      # 设置执行权限
      sudo chmod +x /usr/local/bin/docker-compose
      
      # 创建软链接到 PATH 目录
      sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
      
      echo "✅ Docker Compose 安装完成"
    else
      echo "❌ Docker Compose 安装失败，请手动安装"
      echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
    fi
  fi

elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "ol" ]]; then
  sudo yum install -y yum-utils
  
  # 尝试多个国内镜像源
  echo "正在配置 Docker 源..."
  DOCKER_REPO_ADDED=false
  
  # 创建Docker仓库配置文件，直接使用国内镜像地址
  echo "正在创建 Docker 仓库配置..."
  
  # 根据系统版本选择正确的仓库路径
  # 使用数值比较以支持版本10及以上
  VERSION_MAJOR="${VERSION_ID%%.*}"
  if [[ "$VERSION_MAJOR" -ge 10 ]]; then
    # CentOS Stream 10+ 使用 CentOS 9 仓库（兼容处理）
    CENTOS_VERSION="9"
    echo "检测到 CentOS/RHEL/Rocky Linux ${VERSION_ID}，使用 CentOS 9 仓库（兼容模式）"
  elif [[ "$VERSION_MAJOR" == "9" ]]; then
    CENTOS_VERSION="9"
    echo "检测到 CentOS/RHEL/Rocky Linux 9，使用 CentOS 9 仓库"
  elif [[ "$VERSION_MAJOR" == "8" ]]; then
    CENTOS_VERSION="8"
    echo "检测到 CentOS/RHEL/Rocky Linux 8，使用 CentOS 8 仓库"
  else
    CENTOS_VERSION="7"
    echo "检测到 CentOS/RHEL/Rocky Linux 7，使用 CentOS 7 仓库"
  fi
  
  # 源1: 阿里云镜像
  echo "尝试配置阿里云 Docker 源..."
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
  
  if sudo yum makecache; then
    DOCKER_REPO_ADDED=true
    echo "✅ 阿里云 Docker 源配置成功"
  else
    echo "❌ 阿里云 Docker 源配置失败，尝试下一个源..."
  fi
  
  # 源2: 腾讯云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置腾讯云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 腾讯云 Docker 源配置成功"
    else
      echo "❌ 腾讯云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源3: 华为云镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置华为云 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.huaweicloud.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.huaweicloud.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 华为云 Docker 源配置成功"
    else
      echo "❌ 华为云 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源4: 中科大镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置中科大 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 中科大 Docker 源配置成功"
    else
      echo "❌ 中科大 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源5: 清华大学镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置清华大学 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 清华大学 Docker 源配置成功"
    else
      echo "❌ 清华大学 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 源6: 网易镜像
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "尝试配置网易 Docker 源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.163.com/docker-ce/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.163.com/docker-ce/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 网易 Docker 源配置成功"
    else
      echo "❌ 网易 Docker 源配置失败，尝试下一个源..."
    fi
  fi
  
  # 如果所有国内源都失败，尝试官方源
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "所有国内源都失败，尝试官方源..."
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/${CENTOS_VERSION}/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
    
    if sudo yum makecache; then
      DOCKER_REPO_ADDED=true
      echo "✅ 官方 Docker 源配置成功"
    else
      echo "❌ 官方 Docker 源也配置失败"
    fi
  fi
  
  if [[ "$DOCKER_REPO_ADDED" == "false" ]]; then
    echo "❌ 所有 Docker 源都配置失败，无法继续安装"
    echo "请检查网络连接或手动配置 Docker 源"
    exit 1
  fi

  echo ">>> [3/8] 安装 Docker CE 最新版..."
  
  # 临时禁用 set -e，允许错误处理
  set +e
  
  echo "正在尝试安装 Docker CE（这可能需要几分钟，请耐心等待）..."
  echo "如果安装过程卡住，可能是网络问题或依赖解析中，请等待..."
  
  # 尝试安装 Docker，使用超时机制（30分钟超时）
  INSTALL_OUTPUT=""
  INSTALL_STATUS=1
  
  # 使用 timeout 命令（如果可用）或直接执行
  # 注意：使用 bash -c 确保 sudo 函数在子 shell 中可用
  if command -v timeout &> /dev/null; then
    INSTALL_OUTPUT=$(timeout 1800 bash -c "sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin --nobest" 2>&1)
    INSTALL_STATUS=$?
    if [[ $INSTALL_STATUS -eq 124 ]]; then
      echo "❌ 安装超时（30分钟），可能是网络问题或依赖解析失败"
      INSTALL_STATUS=1
    fi
  else
    INSTALL_OUTPUT=$(sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin --nobest 2>&1)
    INSTALL_STATUS=$?
  fi
  
  # 重新启用 set -e
  set -e
  
  if [[ $INSTALL_STATUS -eq 0 ]]; then
    echo "✅ Docker CE 安装成功"
  else
    # 显示详细错误信息
    echo ""
    echo "❌ Docker CE 批量安装失败"
    echo "错误详情："
    echo "$INSTALL_OUTPUT" | tail -20
    echo ""
    
    # 检查错误类型
    if echo "$INSTALL_OUTPUT" | grep -qiE "(timeout|timed out|connection|网络|network)"; then
      echo "⚠️  检测到可能的网络问题，请检查网络连接"
    fi
    if echo "$INSTALL_OUTPUT" | grep -qiE "(repo|repository|仓库|not found|找不到)"; then
      echo "⚠️  检测到可能的仓库配置问题，请检查 Docker 源配置"
    fi
    
    echo "正在尝试逐个安装组件..."
    
    # 临时禁用 set -e
    set +e
    
    # 逐个安装组件
    echo "  - 正在安装 containerd.io..."
    CONTAINERD_OUTPUT=$(sudo yum install -y containerd.io --nobest 2>&1)
    CONTAINERD_STATUS=$?
    if [[ $CONTAINERD_STATUS -eq 0 ]]; then
      echo "  ✅ containerd.io 安装成功"
    else
      echo "  ❌ containerd.io 安装失败"
      echo "  错误信息: $(echo "$CONTAINERD_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce-cli..."
    DOCKER_CLI_OUTPUT=$(sudo yum install -y docker-ce-cli --nobest 2>&1)
    DOCKER_CLI_STATUS=$?
    if [[ $DOCKER_CLI_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce-cli 安装成功"
    else
      echo "  ❌ docker-ce-cli 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CLI_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-ce..."
    DOCKER_CE_OUTPUT=$(sudo yum install -y docker-ce --nobest 2>&1)
    DOCKER_CE_STATUS=$?
    if [[ $DOCKER_CE_STATUS -eq 0 ]]; then
      echo "  ✅ docker-ce 安装成功"
    else
      echo "  ❌ docker-ce 安装失败"
      echo "  错误信息: $(echo "$DOCKER_CE_OUTPUT" | tail -5)"
    fi
    
    echo "  - 正在安装 docker-buildx-plugin..."
    BUILDX_OUTPUT=$(sudo yum install -y docker-buildx-plugin --nobest 2>&1)
    BUILDX_STATUS=$?
    if [[ $BUILDX_STATUS -eq 0 ]]; then
      echo "  ✅ docker-buildx-plugin 安装成功"
    else
      echo "  ⚠️  docker-buildx-plugin 安装失败（可选组件，不影响核心功能）"
    fi
    
    # 重新启用 set -e
    set -e
    
    # 检查是否至少安装了核心组件
    if ! command -v docker &> /dev/null; then
      echo "❌ 包管理器安装完全失败，尝试二进制安装..."
      
      # 二进制安装备选方案
      echo "正在下载 Docker 二进制包..."
      
      # 尝试多个下载源
      DOCKER_BINARY_DOWNLOADED=false
      
      # 源1: 阿里云镜像
      echo "尝试从阿里云镜像下载 Docker 二进制包..."
      if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
        DOCKER_BINARY_DOWNLOADED=true
        echo "✅ 从阿里云镜像下载成功"
      else
        echo "❌ 阿里云镜像下载失败，尝试下一个源..."
      fi
      
      # 源2: 腾讯云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从腾讯云镜像下载..."
        if curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从腾讯云镜像下载成功"
        else
          echo "❌ 腾讯云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源3: 华为云镜像
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从华为云镜像下载..."
        if curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从华为云镜像下载成功"
        else
          echo "❌ 华为云镜像下载失败，尝试下一个源..."
        fi
      fi
      
      # 源4: 官方源
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "false" ]]; then
        echo "尝试从官方源下载..."
        if curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-20.10.24.tgz -o /tmp/docker.tgz --connect-timeout 10 --max-time 60; then
          DOCKER_BINARY_DOWNLOADED=true
          echo "✅ 从官方源下载成功"
        else
          echo "❌ 官方源下载失败"
        fi
      fi
      
      if [[ "$DOCKER_BINARY_DOWNLOADED" == "true" ]]; then
        echo "正在解压并安装 Docker 二进制包..."
        sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
        sudo chmod +x /usr/bin/docker*
        
        # 创建 systemd 服务文件
        sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

        # 创建 docker.socket 文件
        sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

        # 创建 docker 用户组
        sudo groupadd docker 2>/dev/null || true
        
        echo "✅ Docker 二进制安装成功"
      else
        echo "❌ 所有下载源都失败，无法安装 Docker"
        echo "请检查网络连接或手动安装 Docker"
        exit 1
      fi
    fi
  fi
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  echo ">>> [3.5/8] 安装 Docker Compose..."
  # 安装最新版本的 docker-compose，直接使用 GitHub 官方源
  echo "正在下载 Docker Compose..."
  
  # 直接使用 GitHub 官方源（最可靠）
  echo "正在从 GitHub 官方源下载 Docker Compose..."
  if sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose --connect-timeout 30 --max-time 120; then
    DOCKER_COMPOSE_DOWNLOADED=true
    echo "✅ 从 GitHub 官方源下载成功"
  else
    echo "❌ GitHub 官方源下载失败"
    echo "💡 建议检查网络连接或使用代理"
  fi
  
  # 检查是否下载成功
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "false" ]]; then
    echo "❌ 所有下载源都失败了，尝试使用包管理器安装..."
    
    # 使用包管理器作为备选方案
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" || "$OS" == "deepin" ]]; then
      if sudo apt-get install -y docker-compose-plugin; then
        echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
        DOCKER_COMPOSE_DOWNLOADED=true
      else
        echo "❌ 包管理器安装也失败了"
      fi
    elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "ol" || "$OS" == "kylin" || "$OS" == "uos" || "$OS" == "uniontechos" ]]; then
      if sudo yum install -y docker-compose-plugin; then
        echo "✅ 通过包管理器安装 docker-compose-plugin 成功"
        DOCKER_COMPOSE_DOWNLOADED=true
      else
        echo "❌ 包管理器安装也失败了"
      fi
    fi
  fi
  
  if [[ "$DOCKER_COMPOSE_DOWNLOADED" == "true" ]]; then
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接到 PATH 目录
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose 安装完成"
  else
    echo "❌ Docker Compose 安装失败，请手动安装"
    echo "建议访问: https://docs.docker.com/compose/install/ 查看手动安装方法"
  fi
else
  echo "❌ 暂不支持该系统: $OS"
  echo "💡 若需适配本系统，请到轩辕镜像官网提交工单寻求支持："
  echo "   https://xuanyuan.cloud/tickets"
  exit 1
fi

echo ">>> [5/8] 配置国内镜像..."

# 循环等待用户选择镜像版本
while true; do
    echo "请选择版本:"
    echo "1) 轩辕镜像免费版 (域名: docker.xuanyuan.me)"
    echo "2) 轩辕镜像专业版 (专属域名 *.xuanyuan.run / *.xuanyuan.dev 不含免费版域名)"
    echo "3) 恢复/重置镜像相关配置"
    read -p "请输入选择 [1/2/3]: " choice
    
    if [[ "$choice" == "1" || "$choice" == "2" ]]; then
        break
    elif [[ "$choice" == "3" ]]; then
        restore_docker_daemon_config
        exit $?
    else
        echo "❌ 无效选择，请输入 1、2 或 3"
        echo ""
    fi
done

mirror_list=""

if [[ "$choice" == "2" ]]; then
  read -p "请输入您的轩辕镜像专属域名 (访问官网获取：https://xuanyuan.cloud): " custom_domain

  # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
  if [[ "$custom_domain" == *.xuanyuan.run ]]; then
    custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
    mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_dev"
]
EOF
)
  elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
    custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
    mirror_list=$(cat <<EOF
[
  "https://$custom_domain",
  "https://$custom_domain_run"
]
EOF
)
  else
    mirror_list=$(cat <<EOF
[
  "https://$custom_domain"
]
EOF
)
  fi
else
  mirror_list=$(cat <<EOF
[
  "https://docker.xuanyuan.me"
]
EOF
)
fi

sudo mkdir -p /etc/docker

# 根据用户选择设置 insecure-registries
if [[ "$choice" == "2" ]]; then
  # 清理用户输入的域名，移除协议前缀
  custom_domain=$(echo "$custom_domain" | sed 's|^https\?://||')
  
  # 专业版：*.xuanyuan.run / *.xuanyuan.dev 成对配置（不含 docker.xuanyuan.me）
  if [[ "$custom_domain" == *.xuanyuan.run ]]; then
    custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
    insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_dev"
]
EOF
)
  elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
    custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
    insecure_registries=$(cat <<EOF
[
  "$custom_domain",
  "$custom_domain_run"
]
EOF
)
  else
    insecure_registries=$(cat <<EOF
[
  "$custom_domain"
]
EOF
)
  fi
else
  # 免费版：仅配置 docker.xuanyuan.me
  insecure_registries=$(cat <<EOF
[
  "docker.xuanyuan.me"
]
EOF
)
fi

# 准备 DNS 配置字符串
dns_config=""
if [[ "$SKIP_DNS" != "true" ]]; then
  if ! grep -q "nameserver" /etc/resolv.conf; then
     dns_config=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
  else
     echo "ℹ️  检测到系统已配置 DNS，跳过 Docker DNS 配置以避免冲突"
  fi
fi

cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_config
}
EOF

# 避免在容器/无 systemd 环境反复调用 systemctl 导致 “PID 1 / bus” 报错
SCRIPT_SYSTEMD_OK=false
if command -v systemctl &>/dev/null; then
  PID1_COMM_SCRIPT=$(tr -d '\0' < /proc/1/comm 2>/dev/null || echo "")
  if [[ "$PID1_COMM_SCRIPT" == "systemd" ]] && systemctl show-environment &>/dev/null 2>&1; then
    SCRIPT_SYSTEMD_OK=true
  fi
fi

if [[ "$SCRIPT_SYSTEMD_OK" == "true" ]]; then
  sudo systemctl daemon-reexec || true
  sudo systemctl restart docker || true
else
  echo "ℹ️  未检测到可用 systemd，跳过 systemctl 重载 Docker（容器或无 dbus 环境常见）"
fi

echo ">>> [6/8] 安装完成！"
echo "🎉Docker 镜像已配置完成"
echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
echo "官方网站: https://xuanyuan.cloud/"

echo ">>> [7/8] 重载 Docker 配置并重启服务..."
if [[ "$SCRIPT_SYSTEMD_OK" == "true" ]]; then
  sudo systemctl daemon-reexec || true
  sudo systemctl restart docker || true
else
  echo "ℹ️  无 systemd 时请在完整系统执行: sudo systemctl restart docker，或手动: sudo dockerd &"
fi

# 等待 Docker 服务完全启动
echo "等待 Docker 服务启动..."
sleep 3

# 验证 Docker：优先 docker info（无 systemd 时 systemctl 不可用）
DOCKER_VERIFIED=false
if docker info &>/dev/null; then
  DOCKER_VERIFIED=true
elif [[ "$SCRIPT_SYSTEMD_OK" == "true" ]] && systemctl is-active --quiet docker 2>/dev/null; then
  DOCKER_VERIFIED=true
fi

if [[ "$DOCKER_VERIFIED" == "true" ]]; then
    echo "✅ Docker 服务已成功启动"
    echo "✅ 镜像配置已生效"
    
    # 显示当前配置的镜像源
    echo "当前配置的镜像源:"
    if [[ "$choice" == "2" ]]; then
        if [[ "$custom_domain" == *.xuanyuan.run ]]; then
            custom_domain_dev="${custom_domain%.xuanyuan.run}.xuanyuan.dev"
            echo "  - https://$custom_domain (优先)"
            echo "  - https://$custom_domain_dev (备用)"
        elif [[ "$custom_domain" == *.xuanyuan.dev ]]; then
            custom_domain_run="${custom_domain%.xuanyuan.dev}.xuanyuan.run"
            echo "  - https://$custom_domain (优先)"
            echo "  - https://$custom_domain_run (备用)"
        else
            echo "  - https://$custom_domain"
        fi
    else
        echo "  - https://docker.xuanyuan.me"
    fi
    
    echo ""
    echo "🎉 安装和配置完成！"
    echo ""
    
    # 将执行脚本的用户添加到 docker 组
    echo ">>> [8/8] 配置用户权限..."
    
    # 定义函数：安全地添加用户到 docker 组
    add_user_to_docker_group() {
        local target_user="$1"
        if ! groups "$target_user" | grep -q "\bdocker\b"; then
            echo "⚠️  注意：将用户 $target_user 加入 docker 组意味着赋予该用户 root 级权限。"
            echo "⚠️  这可能会带来安全风险。如果您不确定，请选择 'n'。"
            read -p "是否继续将 $target_user 添加到 docker 组？[Y/n] " confirm_add_group
            confirm_add_group=${confirm_add_group:-Y}
            
            if [[ "$confirm_add_group" =~ ^[Yy]$ ]]; then
                sudo usermod -aG docker "$target_user" 2>/dev/null || true
                echo "✅ 已将用户 $target_user 添加到 docker 组"
                echo "⚠️  请重新登录或执行 'newgrp docker' 使权限生效"
            else
                echo "ℹ️  已跳过用户组配置"
            fi
        else
            echo "✅ 用户 $target_user 已在 docker 组中"
        fi
    }

    if [ -n "$SUDO_USER" ]; then
        # 如果通过 sudo 执行
        add_user_to_docker_group "$SUDO_USER"
    elif [ "$(id -u)" -ne 0 ]; then
        # 如果直接以非 root 用户执行
        add_user_to_docker_group "$USER"
    else
        # 如果已经是 root 用户，提示信息
        echo "ℹ️  当前以 root 用户执行，无需添加到 docker 组"
    fi
    
    echo ""
    echo "轩辕镜像 · 专业版 - 开发者首选的专业 Docker 镜像高效稳定拉取服务"
    echo "官方网站: https://xuanyuan.cloud/"
else
    echo "❌ 无法连接到 Docker daemon（可能未安装 docker-ce 或未启动）。/etc/docker/daemon.json 已写入。"
    echo "💡 统信等环境可先执行: sudo dnf remove -y docker-runc && sudo dnf install -y --allowerasing docker-ce"
    echo "💡 在物理机/虚拟机: sudo systemctl enable --now docker；无 systemd 环境可尝试: sudo dockerd &"
    exit 1
fi)
}

# ---------- Linux 服务器工具箱（原 linux.sh 全部内容，子 shell 隔离） ----------
linux_tools_main() {
(

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'


# 获取服务器IP地址
server_ip=$(hostname -I)

uptime=$(uptime -p)
uptime_cn=$(echo $uptime | sed 's/up/已运行/; s/hour/时/; s/minutes/分/; s/days/天/; s/months/月/')



show_menu() {
    clear
    local greeting
    greeting=$(get_greeting)
    echo -e "
===================================================
✪  工具名称：${RED}数据渔港Linux工具${RESET}        
✪  工具版本：${GREEN}V1.0.4.1${RESET}      
✪  服务器IP：$server_ip
✪  运行时间：$uptime_cn
--------------------[综合菜单]---------------------

   1. 系统操作菜单(修改密码、SSH端口、更新系统等)
   2. 网络操作菜单(开/关ping、检测UDP、绑定IP等)
   3. 文件操作菜单(挂载硬盘、远程下载文件等)
   4. 宝塔面板菜单(挂载硬盘、一键安装宝塔产品)
   5. 宿主机菜单(云服务器不要尝试开启虚拟化)           
   
--------------------[快捷功能]---------------------

   6. BBR一键脚本       
   7. 回程路由可视化脚本          
   8. IP质量检测脚本       
   9. 流媒体解锁检测脚本       
   10. 融合怪VPS测试一键脚本         
   11. Linux系统一键换源(默认版)
   12. Linux系统一键换源(教育网)      
   13. 通用一键安装宝塔最新正式版
   14. 一键安装1panel面板(国内服务器请先换源)
   15. 一键TCP窗口大带宽调优
   16. Docker一键安装配置(轩辕镜像)
   17. 宝塔数据盘自动挂载(auto_disk)
   q. 退出脚本
   
--------------------[服务器推荐]---------------------

${CYAN}数据渔港-爆款香港服务器，CTG+CN2高速带宽、快速稳定、平均延迟10+ms 速度快，免备案
官网：https://datafh.cn ${RESET}       

===================================================
$greeting
	"
}



# 系统操作菜单
system_menu() {
    clear
    echo "=== 系统操作菜单 ==="
    echo "1. 一键重启服务器"
    echo "2. 一键修改密码"
    echo "3. 一键同步上海时间"
    echo "4. 一键修改SSH端口"
    echo "5. 一键修改DNS"
    echo "6. 一键开启/关闭SSH登录"
    echo "7. 一键更新CentOS最新版系统"
    echo "8. 一键更新Ubuntu最新版系统"
    echo "9. 一键更新Debian最新版系统"
    echo "10. 一键更换CentOS yum源"
    echo "11. 一键更换Ubuntu apt源"
    echo "12. 一键更换Debian apt源"
    echo "13. 一键创建子用户或管理员"
    echo "14. 一键查看当前与服务器连接的IP"
    echo "15. 一键修改服务器主机名"
    echo "16. 一键更换CentOS8 stream仓库源"
    echo "17. 一键查看SSH登录成功的IP地址"
    echo "q. 返回上级菜单"
    echo "===================="
}



# 网络操作菜单
network_menu() {
    clear
    echo "=== 网络操作菜单 ==="
    echo "1. 一键重启网卡"
    echo "2. 一键开启/关闭Ping"
    echo "3. 一键绑定附加IP"
    echo "4. 一键查看服务器地理位置"
    echo "5. 一键查看服务器IP原生地址"
    echo "6. 一键查看服务器配置信息"
    echo "7. 一键检测服务器是否屏蔽UDP"
    echo "8. 一键VPS的IP映射至独立服务器"
    echo "9. 一键关闭VPS的IP映射"
    echo "10. 一键开启四层端口转发"
    echo "11. 一键关闭四层端口转发"
    echo "12. 一键查看服务器在使用的端口"
    echo "13. 一键查看什么IP在跑带宽"
    echo "q. 返回上级菜单"
    echo "===================="
}



# 文件传输菜单
file_transfer_menu() {
    clear
    echo "=== 文件传输菜单 ==="
    echo "1. 一键上传文件到远程服务器"
    echo "2. 一键从远程服务器下载文件"
    echo "3. 一键查看所有硬盘分区信息(挂载硬盘前建议查看)"
    echo "4. 一键自定义挂载数据盘"
    echo "5. 一键自定义卸载数据盘"
    echo "6. 一键自定义格式化数据盘"
    echo "7. 一键修复硬盘分区超级坏块"
    echo "8. 一键设置开机启动脚本"
    echo "9. 一键查询关键词文件内容(可用于审查违规)"
    echo "10. 一键查看SSH历史输入命令"
    echo "11. 一键清空SSH历史输入命令"
    echo "q. 返回上级菜单"
    echo "===================="
}



# 根据当前时间返回问候语
get_greeting() {
    local hour=$(date +"%H")
    case $hour in
        1|2|3|4|5|6|7|8|9|10|11)
            echo "上午好！欢迎使用 数据渔港linux工具"
            ;;
        12|13|14|15|16|17|18)
            echo "下午好！欢迎使用 数据渔港linux工具"
            ;;
         *)
            echo "晚上好！欢迎使用 数据渔港linux工具"
            ;;
    esac
}



# 函数：启动 iftop
start_iftop() {
    echo "启动 iftop，按 CTRL+C 退出..."
    sudo iftop
}



# 函数：检查并安装 iftop
check_and_install_iftop() {
    if ! command -v iftop &> /dev/null; then
        echo -e "${GREEN}正在检查 iftop 是否已安装...${NC}"
        # 检测Linux发行版并安装 iftop
        if [ -f /etc/debian_version ]; then
            echo -e "${GREEN}检测到 Debian/Ubuntu 系统，正在安装 iftop...${NC}"
              sudo apt-get update && sudo apt-get install -y iftop
        elif [ -f /etc/centos-release ]; then
            echo -e "${GREEN}检测到 CentOS 系统，正在安装 iftop...${NC}"
            sudo yum install -y epel-release  # 确保有 EPEL 源
            sudo yum install -y iftop
        else
            echo -e "${RED}不支持的系统，无法安装 iftop。${NC}"
        fi
    fi
}



# 查看历史记录
view_history() {
    echo "查看历史记录..."
    if [ -f ~/.bash_history ]; then
        cat ~/.bash_history
    else
        echo "没有找到历史记录文件。"
    fi
    exit 0
}

#BBR一键脚本
bbryj(){
    # 使用无限循环来不断地询问用户是否需要继续安装
    while true; do
        # 提示用户输入Y(Y/N)，并将输入值存储在变量answer中
        read -p "Debian类系统无需安装，默认自带，如需继续安装请输入Y(Y/N) " answer
        # 使用case语句根据用户的输入执行相应的操作
        case $answer in
            # 如果用户输入Y或y，则下载并执行tcp.sh脚本
            [Yy]* ) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh;;
            # 如果用户输入N或n，则跳出循环
            [Nn]* ) break;;
            # 如果用户输入其他字符，则默认执行下载并执行tcp.sh脚本的操作
            * ) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh;;
        esac
    done
}

#流媒体检测脚本
lmtjc(){
    bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)
}

# 清空历史记录
clear_history() {
    # 使用sed命令清空.bash_history文件
    sed -i '' 1d ~/.bash_history
    # 确保文件是空的
    echo "" > ~/.bash_history
    echo "sed：已经读取 1d："
    echo "历史记录已清空。"
}



# 定义函数：安装 dig 命令
install_dig() {
    echo "正在检查 dig 命令..."
    if ! command -v dig &> /dev/null; then
        echo "dig 命令未找到，正在安装..."
        case $(uname -s) in
            Linux)
                if [ -x "$(command -v apt-get)" ]; then
                    sudo apt-get update && sudo apt-get install -y dnsutils
                elif [ -x "$(command -v yum)" ]; then
                    sudo yum install bind-utils
                elif [ -x "$(command -v dnf)" ]; then
                    sudo dnf install bind-utils
                else
                    echo "不支持的Linux发行版"
                    exit 1
                fi
                ;;
            *)
                echo "不支持的操作系统"
                exit 1
                ;;
        esac
    else
        echo "dig 命令已安装."
    fi
}



# 定义一个函数来检测8.8.8.8的UDP DNS解析
check_dns_udp() {
    echo "正在测试8.8.8.8的UDP DNS解析..."
    if dig @8.8.8.8 -p 53 google.com > /dev/null; then
        echo "8.8.8.8的UDP DNS解析正常 UDP正常。"
    else
        echo "8.8.8.8的UDP DNS解析失败 UDP屏蔽。"
    fi
}



# 更新YUM仓库源
update_repo() {
    echo "正在更新YUM仓库源到阿里云镜像..."
    # 使用sed命令修改仓库配置文件
    sed -e "s|^mirrorlist=|#mirrorlist=|g" -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/|baseurl=https://mirrors.aliyun.com/centos-vault/|g" -i.bak /etc/yum.repos.d/CentOS-Stream-*.repo

    # 刷新YUM缓存
    yum makecache
    echo "YUM仓库源更新完成。"
}


# 检测操作系统并设置日志文件路径
log_file_path=""
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        centos)
            log_file_path="/var/log/secure"
            ;;
        ubuntu|debian)
            log_file_path="/var/log/auth.log"
            ;;
        *)
            echo "不支持的操作系统"
            exit 1
            ;;
    esac
else
    echo "无法检测到操作系统"
    exit 1
fi



# 查看登录成功的IP
show_login_ips() {
    # 从正确的日志文件中提取登录成功的IP地址
    grep 'sshd.*Accepted' "$log_file_path" | awk '{print $11}' | sort | uniq
}

# 修复硬盘分区坏块
repair_badblocks() {
    read -p "请输入要修复坏块的硬盘分区（例如：/dev/home）：" partition
    echo "开始修复硬盘分区坏块..."
    xfs_repair $partition -L
    echo "修复完成！"
}



# 审查文件内容关键词（自定义目录搜索）
review_files_custom() {
    echo "请输入要搜索的目录路径："
    read directory_path
    if [ -d "$directory_path" ]; then
        echo "请输入关键词："
        read keyword
        echo "开始搜索关键词 '$keyword' 在目录 '$directory_path' 中..."
        grep -rl "$keyword" "$directory_path"
    else
        echo "输入的路径不是有效的目录，请重新输入。"
    fi
}



# 修改主机名的函数
change_hostname() {
    local new_hostname
    read -p "请输入新的主机名：" new_hostname
    if [ -n "$new_hostname" ]; then
        sudo hostnamectl set-hostname "$new_hostname"
        if [ $? -eq 0 ]; then
            echo "主机名已成功修改为：$new_hostname"
        else
            echo "修改主机名失败，请检查输入是否有误。"
        fi
    else
        echo "输入的主机名不能为空。"
    fi
}



# 定义函数：关闭 SELinux
disable_selinux() {
    # 检查当前 SELinux 的状态
    sestatus=$(sestatus | awk '{print $3}')

    if [[ $sestatus == "enabled" ]]; then
        echo "当前 SELinux 状态为已启用。"
        echo "正在关闭 SELinux..."

        # 临时禁用 SELinux
        setenforce 0

        # 检查 SELinux 是否成功禁用
        if [[ $(sestatus | awk '{print $3}') == "disabled" ]]; then
            echo "SELinux 已成功禁用。"
        else
            echo "无法禁用 SELinux。"
        fi
    else
        echo "当前 SELinux 状态为已禁用。"
    fi
}


# 一键四层转发函数
forwarding() {
    echo "请输入转发端口："
    read source_port
    echo "请输入目标端口："
    read destination_port
    echo "正在进行四层转发，转发端口为 $source_port，目标端口为 $destination_port ..."
    # 使用iptables进行转发
    iptables -t nat -A PREROUTING -p tcp --dport $source_port -j DNAT --to-destination 目标IP:$destination_port
    echo "转发已完成！"
}



# 定义函数：用户自定义脚本
custom_script() {
    read -p "请输入自定义脚本的内容: " script_content

    # 获取当前用户的home目录
    home_dir=$(eval echo ~$USER)

    # 将用户输入的脚本内容保存到文件中
    echo "$script_content" > "$home_dir/my.sh"
    chmod +x "$home_dir/my.sh"

    echo "自定义脚本已保存为 my.sh。"
}

# 一键关闭四层转发函数
disable_forwarding() {
    echo "正在关闭四层转发..."
    # 使用iptables删除转发规则
    iptables -t nat -F
    echo "四层转发已关闭！"
}

# 检查是否已经取消注释net.ipv4.ip_forward=1
check_ip_forwarding() {
    if grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1 已经在 /etc/sysctl.conf 中取消注释"
    else
        # 如果未取消注释，则添加配置并重新加载sysctl配置
        echo "net.ipv4.ip_forward=1 未在 /etc/sysctl.conf 中取消注释"
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo "已添加 net.ipv4.ip_forward=1 并重新加载sysctl配置"
    fi
}

# 关闭端口转发函数
close_port_forwarding() {
    sudo iptables -t nat -F
    echo "IP映射已成功关闭"
}

# 设置端口转发函数
setup_port_forwarding() {
    read -p "请输入VPS的IP地址: " vps_ip
    read -p "请输入VPS上要转发的端口: " vps_port
    read -p "请输入独立服务器的IP地址: " server_ip
    read -p "请输入独立服务器上要映射到的端口: " server_port

    # 执行端口转发设置
    iptables -t nat -A PREROUTING -p tcp --dport $vps_port -j DNAT --to-destination $server_ip:$server_port
    iptables -t nat -A POSTROUTING -p tcp -d $server_ip --dport $server_port -j SNAT --to-source $vps_ip

    echo "端口转发设置成功: $vps_ip:$vps_port -> $server_ip:$server_port"
}



# 挂载数据盘
mount_data_disk() {
    # 确定数据盘设备名
    read -p "请输入数据盘设备名[默认：/dev/vdb1]: " disk_device
    disk_device=${disk_device:-"/dev/vdb1"}

    # 确定挂载点目录
    read -p "请输入挂载点目录[默认：/data]: " mount_point
    mount_point=${mount_point:-"/data"}

    # 检查挂载点目录是否存在
    if [ ! -d "$mount_point" ]; then
        # 挂载点目录不存在，创建目录
        sudo mkdir "$mount_point"
    fi

    # 检查数据盘是否已经被挂载
    if grep -qs "$disk_device" /proc/mounts; then
        echo "数据盘 $disk_device 已经被挂载"
        return
    fi

    # 检查数据盘是否存在
    if [ ! -e "$disk_device" ]; then
        echo "数据盘 $disk_device 不存在"
        return
    fi

    # 挂载数据盘
    sudo mount "$disk_device" "$mount_point"
    echo "数据盘 $disk_device 成功挂载到 $mount_point"
    
    # 将数据盘添加到 /etc/fstab 实现开机自动挂载
    echo "$mount_path $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab

    echo "数据盘已成功挂载到 $mount_point，并已设置为开机自动挂载。"
}

# 尝试安装netstat
install_netstat() {
    if ! command -v netstat &> /dev/null; then
        echo "netstat 未安装，正在尝试安装..."
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            apt-get update && apt-get install -y net-tools
        elif [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
            yum install -y net-tools
        else
            echo "不支持的操作系统"
            exit 1
        fi
    fi
}

# 查看连接到本机的远程IP地址数量
show_connected_ips_count() {
    install_netstat
     netstat -tn | awk '{print $5}' | grep -v 'Address' | cut -d: -f1 | sort | uniq -c | sort -nr
    # 可以根据需要修改端口号或状态
}



function toggle_ssh() {
    if [[ -f /etc/redhat-release ]]; then
        # CentOS
        if sudo systemctl is-active --quiet sshd; then
            sudo systemctl stop sshd
            sudo systemctl disable sshd
            echo "SSH登录已禁用"
        else
            sudo systemctl enable sshd
            sudo systemctl start sshd
            echo "SSH登录已启用"
        fi
    elif [[ -f /etc/lsb-release ]]; then
        # Ubuntu
        if sudo service ssh status | grep "running" >/dev/null; then
            sudo service ssh stop
            sudo systemctl disable ssh
            echo "SSH登录已禁用"
        else
            sudo systemctl enable ssh
            sudo service ssh start
            echo "SSH登录已启用"
        fi
    elif [[ -f /etc/debian_version ]]; then
        # Debian
        if sudo service ssh status | grep "running" >/dev/null; then
            sudo service ssh stop
            sudo systemctl disable ssh
            echo "SSH登录已禁用"
        else
            sudo systemctl enable ssh
            sudo service ssh start
            echo "SSH登录已启用"
        fi
    else
        echo "不支持的操作系统"
    fi
}

function disable_swap() {
    if [[ -f /etc/fstab ]]; then
        sudo sed -i '/swap/d' /etc/fstab
        sudo swapoff -a
        echo "SWAP已关闭"
    else
        echo "无法找到fstab文件"
    fi
}



# 卸载数据盘
umount_data_disk() {
    # 确定挂载点目录
    read -p "请输入挂载点目录[默认：/data]: " mount_point
    mount_point=${mount_point:-"/data"}

    # 检查挂载点目录是否存在
    if [ ! -d "$mount_point" ]; then
        echo "挂载点目录 $mount_point 不存在"
        return
    fi

    # 检查挂载点目录是否被挂载
    if ! grep -qs "$mount_point" /proc/mounts; then
        echo "挂载点目录 $mount_point 未被挂载"
        return
    fi

    # 卸载数据盘
    sudo umount "$mount_point"
    echo "数据盘 $mount_point 成功卸载"
}

# 函数：创建用户并设置密码
create_user() {
    read -p "请输入要创建的用户名: " username

    # 检查用户是否已存在
    if id "$username" &>/dev/null; then
        echo "用户 $username 已存在"
    else
        # 创建用户
        sudo useradd -m $username
        if [ $? -eq 0 ]; then
            echo "用户 $username 创建成功"
            sudo passwd $username

            # 询问是否将用户添加到sudo组
            read -p "是否要将用户 $username 设置为管理员(y/n): " add_sudo
            if [ "$add_sudo" == "y" ]; then
                sudo usermod -aG wheel $username
                echo "用户 $username 已设置为管理员"
            fi
        else
            echo "创建用户 $username 失败"
        fi
    fi
}



# 定义增加IP地址函数
add_ip() {
    read -p "请输入要添加的IP地址：" ip
    read -p "请输入网关：" gateway
    read -p "请输入掩码：" netmask

    # 检查IP地址是否已经存在
    if ip addr show | grep -q $ip; then
        echo "IP地址已经存在，删除已存在的IP地址。"
        ip addr del $ip/$netmask dev eth0
    fi

    # 添加IP地址
    ip addr add $ip/$netmask dev eth0
    ip route add default via $gateway
    echo "IP地址添加成功。"

    # 将添加IP地址的命令添加到 /etc/rc.local 文件中
    echo "ip addr add $ip/$netmask dev eth0" >> /etc/rc.local
    echo "ip route add default via $gateway" >> /etc/rc.local
    
    # 提示用户重启网络接口或服务器
    echo "如果IP地址没有立即生效，请尝试重启网卡或重启服务器。"
}

# 定义函数用于格式化用户指定的数据硬盘
format_disk() {
    read -p "请输入要格式化的数据硬盘设备名称（回车默认/dev/vdb1）：" disk_name
    disk_name=${disk_name:-/dev/vdb1}

    # 检查硬盘是否存在
    if [ ! -b "$disk_name" ]; then
        echo "硬盘 $disk_name 不存在或不可用。"
        exit 1
    fi

    read -p "请输入文件系统类型（回车默认ext4）：" fs_type
    fs_type=${fs_type:-ext4}

    # 确认操作
    read -p "您确定要格式化硬盘 $disk_name 为文件系统 $fs_type 吗？(y/n)：" confirm
    if [ "$confirm" != "y" ]; then
        echo "取消操作。"
        exit 0
    fi

    # 格式化硬盘
    sudo mkfs.$fs_type $disk_name
    if [ $? -eq 0 ]; then
        echo "硬盘 $disk_name 成功格式化为文件系统 $fs_type。"
    else
        echo "无法格式化硬盘 $disk_name。"
    fi
}



# 函数：自定义设置并配置Swap空间
function set_swap() {
    read -p "请输入SWAP大小（单位：GB）: " swap_size

    if [[ ! $swap_size =~ ^[0-9]+$ ]]; then
        echo "无效的输入，请输入一个有效的数字"
        return
    fi

    if [[ -f /etc/fstab ]]; then
        sudo sed -i '/swap/d' /etc/fstab
        sudo swapoff -a

        if [[ -f /swapfile ]]; then
            sudo rm /swapfile
        fi

        sudo fallocate -l ${swap_size}G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile

        echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
        echo "SWAP已设置为 ${swap_size}GB"
        echo "SWAP设置已添加到 /etc/fstab，将在系统启动时自动启用"
    else
        echo "无法找到fstab文件"
    fi
}


# 函数：启用嵌套虚拟化
function enable_nested_virtualization() {
    if [[ -f /sys/module/kvm_intel/parameters/nested ]]; then
        # Intel processor
        sudo modprobe -r kvm_intel
        sudo modprobe kvm_intel nested=1
        echo "已开启虚拟化"
    elif [[ -f /sys/module/kvm_amd/parameters/nested ]]; then
        # AMD processor
        sudo modprobe -r kvm_amd
        sudo modprobe kvm_amd nested=1
        echo "已开启虚拟化"
    else
        echo "不支持的处理器"
    fi
}




# 重启服务器
restart_server() {
    read -p "确认要重启服务器吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在重启服务器..."
        # 在这里添加重启服务器的命令
        sudo reboot
    else
        echo "取消重启服务器"
    fi
}

# 一键修改密码
change_password() {
    username=$(whoami)
    sudo passwd "$username"
    echo "密码已成功修改。"
}

# 函数：显示服务器地理位置
show_server_location() {
    curl ipinfo.io
}

# 函数：显示服务器地理位置（中文）
show_server_location2() {
    curl iplark.com
}




# 同步上海时间函数
sync_shanghai_time() {
    install_ntpdate
    echo "正在同步上海时间..."
    sudo timedatectl set-timezone Asia/Shanghai
    sudo ntpdate cn.pool.ntp.org
    echo "时间同步完成。"
}

# 一键修改 SSH 端口
change_ssh_port() {
    read -p "请输入新的 SSH 端口: " new_port
    sed -i "s/Port [0-9]*/Port $new_port/" /etc/ssh/sshd_config
    systemctl restart sshd
    echo "SSH 端口已修改为 $new_port"
}

# 函数：一键修改DNS1和DNS2
function set_dns() {
    read -p "请输入新的DNS服务器地址: " dns_server
    if [[ -f /etc/redhat-release ]]; then
        # CentOS
        echo "nameserver $dns_server" | sudo tee /etc/resolv.conf >/dev/null
        echo "DNS服务器已修改为 $dns_server"
    elif [[ -f /etc/lsb-release ]]; then
        # Ubuntu
        sudo sed -i "s/nameserver .*/nameserver $dns_server/" /etc/resolv.conf
        echo "DNS服务器已修改为 $dns_server"
    elif [[ -f /etc/debian_version ]]; then
        # Debian
        sudo sed -i "s/nameserver .*/nameserver $dns_server/" /etc/resolv.conf
        echo "DNS服务器已修改为 $dns_server"
    else
        echo "不支持的操作系统"
    fi
}




# 一键更新 CentOS 最新版系统
update_centos() {
    read -p "确认要更新 CentOS 最新版系统吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在更新 CentOS 最新版系统..."
        # 在这里添加更新 CentOS 的命令
        sudo yum update
        echo "CentOS 最新版系统更新完成"
        reboot
    else
        echo "取消更新 CentOS 最新版系统"
    fi
}

# 一键更新 Ubuntu 最新版系统
update_ubuntu() {
    read -p "确认要更新 Ubuntu 最新版系统吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在更新 Ubuntu 最新版系统..."
        # 在这里添加更新 Ubuntu 的命令
        sudo apt update
        sudo apt upgrade -y
        echo "Ubuntu 最新版系统更新完成"
        reboot
    else
        echo "取消更新 Ubuntu 最新版系统"
    fi
}



# 函数：切换KSM状态
toggle_ksm() {
    ksm_status=$(cat /sys/kernel/mm/ksm/run)
    if [ $ksm_status -eq 0 ]; then
        /bin/systemctl start ksm
        /bin/systemctl start ksmtuned
        cat /sys/kernel/mm/ksm/run
        echo "KSM内存回收已开启。"
    else
        /bin/systemctl stop ksmtuned
        /bin/systemctl stop ksm
        echo 0 > /sys/kernel/mm/ksm/run
        echo "KSM内存回收已关闭。"
    fi
}

# 一键更新 Debian 最新版系统
update_debian() {
    read -p "确认要更新 Debian 最新版系统吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在更新 Debian 最新版系统..."
        # 在这里添加更新 Debian 的命令
        sudo apt update
        sudo apt upgrade -y
        echo "Debian 最新版系统更新完成"
        reboot
    else
        echo "取消更新 Debian 最新版系统"
    fi
}



# 更换CentOS 7源为阿里云源的函数
change_centos_to_aliyun() {
    if [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
        echo "正在更换CentOS的源为阿里云源..."
        sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        cat << 'EOF' | sudo tee /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-$releasever - Base - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# 可选的，添加阿里云的额外源
[extras]
name=CentOS-$releasever - Extras - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# 可选的，添加阿里云的更新源
[updates]
name=CentOS-$releasever - Updates - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
EOF
        sudo yum clean all
        sudo yum makecache
        echo "CentOS源更换完成。"
    else
        echo "CentOS源配置文件不存在。"
    fi
}

# 更换Ubuntu 20.04源为阿里云源的函数
change_ubuntu_to_aliyun() {
    if [ -f /etc/apt/sources.list ]; then
        echo "正在更换Ubuntu的源为阿里云源..."
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
        sudo sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
        sudo sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
        echo "Ubuntu源更换完成。"
    else
        echo "Ubuntu源配置文件不存在。"
    fi
}



# 更换Debian源为阿里云源的函数
change_debian_to_aliyun() {
    if [ -f /etc/apt/sources.list ]; then
        echo "正在更换Debian的源为阿里云源..."
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
        sudo sed -i 's|http://[^ ]*|http://mirrors.aliyun.com|' /etc/apt/sources.list
        echo "Debian源更换完成。"
    else
        echo "Debian源配置文件不存在。"
    fi
}

# 检查并安装ntpdate
install_ntpdate() {
    if ! command -v ntpdate &> /dev/null; then
        echo "正在安装ntpdate..."
        if [ -f /etc/redhat-release ]; then
            sudo yum install -y ntpdate
        elif [ -f /etc/debian_version ]; then
            sudo apt-get install -y ntpdate
        else
            echo "不支持的操作系统类型。"
            exit 1
        fi
        echo "ntpdate安装完成。"
    fi
}



# 函数：显示服务器配置信息
show_server_config() {
    echo "=== 服务器配置信息 ==="
    echo "CPU核心数:"
    lscpu | grep -w "CPU(s):" | grep -v "\-"
    lscpu | grep -w "Model name:"
    echo "CPU频率:"
    lscpu | grep -w "CPU MHz"
    echo "虚拟化类型:"
    lscpu | grep -w "Hypervisor vendor:"
   echo "系统版本:"
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "Ubuntu $DISTRIB_RELEASE"
    elif [ -f /etc/debian_version ]; then
        DEBIAN_VERSION=$(cat /etc/debian_version)
        echo "Debian $DEBIAN_VERSION"
    elif [ -f /etc/centos-release ]; then
        CENTOS_VERSION=$(cat /etc/centos-release)
        echo "CentOS $CENTOS_VERSION"
    else
        echo "无法识别的系统类型"
    fi
    echo "内存信息:"
    free -h
    echo "硬盘信息:"
    df -h
}



# 一键重启网卡
function restart_network_card() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os=$ID
    elif [ -f /etc/centos-release ]; then
        os="centos"
    else
        echo "Unsupported operating system."
        return
    fi

    if [ "$os" == "debian" ]; then
        sudo systemctl restart networking
    elif [ "$os" == "ubuntu" ]; then
        sudo systemctl restart networkd-dispatcher
    elif [ "$os" == "centos" ]; then
        sudo service network restart
    else
        echo "Unsupported operating system."
        return
    fi

    echo "网卡已重启"
}

# 上传文件到远程服务器
upload_file() {
    # 输入远程服务器的 IP 地址或域名
    read -p "请输入远程服务器的 IP 地址或域名: " remote_server

    # 输入远程服务器的用户名
    read -p "请输入远程服务器的用户名: " remote_user

    # 输入远程服务器的目标路径
    read -p "请输入远程服务器的目标路径: " remote_path

    # 输入本地文件的路径
    read -p "请输入要传输的本地文件的路径: " local_file

    # 使用 scp 命令传输文件
    echo "正在传输文件到远程服务器..."
    scp "$local_file" "$remote_user@$remote_server:$remote_path"
    echo "文件传输完成"
}



# 从远程服务器下载文件
download_file() {
    # 输入远程服务器的 IP 地址或域名
    read -p "请输入远程服务器的 IP 地址或域名: " remote_server

    # 输入远程服务器的用户名
    read -p "请输入远程服务器的用户名: " remote_user

    # 输入远程服务器的文件路径
    read -p "请输入远程服务器的文件路径: " remote_file

    # 输入本地保存文件的路径
    read -p "请输入本地保存文件的路径: " local_path

    # 使用 scp 命令从远程服务器下载文件
    echo "正在从远程服务器下载文件..."
    scp "$remote_user@$remote_server:$remote_file" "$local_path"
    echo "文件下载完成"
}



# 函数：一键开启/关闭Ping
toggle_ping() {
    if [ "$(sysctl -n net.ipv4.icmp_echo_ignore_all)" = "1" ]; then
        echo "正在开启Ping..."
        sudo sysctl -w net.ipv4.icmp_echo_ignore_all=0
        echo "已开启Ping。"
    else
        echo "正在关闭Ping..."
        sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
        echo "已关闭Ping。"
    fi
}

# 询问是否重启服务器
ask_reboot() {
    read -p "更新完成，是否重启服务器？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        restart_server
    else
        echo "更新完成，服务器未重启"
    fi
}



# 主循环
while true
do
    show_menu
    read -p "请输入选项: " choice
    case $choice in
        1)
            while true
            do
                system_menu
                read -p "请输入选项: " system_choice
                case $system_choice in
                    1)
                        restart_server
                        ;;
                    2)
                        change_password
                        ;;
                    3)
                        sync_shanghai_time
                        ;;
                    4)
                        change_ssh_port
                        ;;
                    5)
                        set_dns
                        ;;
                    6)
                        toggle_ssh
                        ;;
                    7)
                        update_centos
                        ;;
                    8)
                        update_ubuntu
                        ;;
                    9)
                        update_debian
                        ;;
                    10) change_centos_to_aliyun;;
                    11) change_ubuntu_to_aliyun;;
                    12) change_debian_to_aliyun;;
                    13)
                        create_user
                        ;;     
                    14)
                        show_connected_ips_count
                        ;;     
                    15)
                        change_hostname
                        ;;   
                    16) update_repo;;
                    
                    17) show_login_ips;;
                    q)
                        break
                        ;;
                    *)
                        echo "无效的选项，请重新输入"
                        ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
            
        2)
            while true
            do
                network_menu
                read -p "请输入选项: " network_choice
                case $network_choice in
                    1)
                        restart_network_card
                        ;;
                    2)
                        toggle_ping
                        ;;
                    3)
                        add_ip
                        ;;
                    4)
                        show_server_location
                        ;;
                    5)
                        show_server_location2
                        ;;    
                    6)
                        show_server_config
                        ;; 
                        
                    7)  install_dig
                        check_dns_udp
                        ;;       
                    8)
                        check_ip_forwarding
                        setup_port_forwarding
                        ;;
                    9)  
                        close_port_forwarding
                        ;;
                    10)
                        forwarding
                        ;;
                    11)
                        disable_forwarding
                        ;;
                    12)
                        netstat -tuln
                        ;; 
                    13)
                        check_and_install_iftop
                        start_iftop
                        ;;   
                        
                    q)
                        break
                        ;;
                    *)
                        echo "无效的选项，请重新输入"
                        ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
            
        
        3)
            while true
            do
                file_transfer_menu
                read -p "请输入选项: " file_transfer_choice
                case $file_transfer_choice in
                    1)
                        upload_file
                        ;;
                    2)
                        download_file
                        ;;
                    3)
                        fdisk -l
                        ;;    
                    4)
                        mount_data_disk
                        ;;
                    5)
                        umount_data_disk
                        ;;   
                    6)
                        format_disk
                        ;; 
                    7)
                        repair_badblocks
                        ;;     
                    8)
                        custom_script
                        ;;
                    9) review_files_custom;;
                    10) view_history ;;
                    11) clear_history ;;
                    q)    
                        break
                        ;;
                    *)
                        echo "无效的选项，请重新输入"
                        ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
            
       4)
            while true
            do
                clear
                echo "=== 宝塔面板菜单 ==="
                echo "1. 宝塔官方一键挂载硬盘脚本"
                echo "2. 安装堡塔主机安全系统"
                echo "3. 安装Centos/OpenCloud/Alibaba稳定版"
                echo "4. 安装Ubuntu/Deepin宝塔稳定版"
                echo "5. 安装Debian宝塔稳定版"
                echo "6. 安装宝塔面板最新正式版"
                echo "7. 一键安装宝塔WAF最新版"
                echo "q. 返回上级菜单"
                echo "===================="
                read -p "请输入选项: " other_choice
                case $other_choice in
                
               1)
                    while true
                do
                    clear
                    echo "请选择确认并选择您的操作系统"
                    echo "1. CentOS系统"
                    echo "2. Ubuntu系统"
                    echo "3. Debian系统"
                    echo "q. 返回上级菜单"
                    read -p "请输入选项: " other_choice
                    case $other_choice in
                    
                    1)
                    yum install wget -y && wget -O auto_disk.sh http://download.bt.cn/tools/auto_disk.sh && bash auto_disk.sh;;
                    2)
                    wget -O auto_disk.sh http://download.bt.cn/tools/auto_disk.sh && sudo bash auto_disk.sh;;
                    3)
                    wget -O auto_disk.sh http://download.bt.cn/tools/auto_disk.sh && sudo bash auto_disk.sh;;
                    q)
                    break
                    ;;
                    esac
                    done
                    ;;
                
               2) 
                   URL=https://download.bt.cn/bthids/scripts/install_hids.sh && if [ -f /usr/bin/curl ];then curl -sSO "$URL" ;else wget -O install_hids.sh "$URL";fi;bash install_hids.sh;;  
               3) 
                   url=https://download.bt.cn/install/install_lts.sh;if [ -f /usr/bin/curl ];then curl -sSO $url;else wget -O install_lts.sh $url;fi;bash install_lts.sh 02a5b375;; 
               4) 
                   wget -O install.sh https://download.bt.cn/install/install_lts.sh && sudo bash install.sh 02a5b375;;    
               5) 
                   wget -O install.sh https://download.bt.cn/install/install_lts.sh && bash install.sh 02a5b375;; 
               6) 
                   if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh 02a5b375;;    
               7) 
                   URL=https://download.bt.cn/cloudwaf/scripts/install_cloudwaf.sh && if [ -f /usr/bin/curl ];then curl -sSO "$URL" ;else wget -O install_cloudwaf.sh "$URL";fi;bash install_cloudwaf.sh;;    
               q)   
                   break
                   ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
            
        5)
            while true
            do
                clear
                echo "=== 宿主机菜单 ==="
                echo "1. 一键开启云服务器虚拟化"
                echo "2. 一键自定义设置SWAP虚拟内存"
                echo "3. 一键关闭SWAP虚拟内存"
                echo "4. 一键开启/关闭KSM内存回收"
                echo "5. 一键关闭SELinux"
                echo "q. 返回上级菜单"
                echo "===================="
                read -p "请输入选项: " other_choice
                case $other_choice in
                
               1) 
                   enable_nested_virtualization;; 
                 
               2) 
                   set_swap;;  
                   
               3)    
                   disable_swap;;  
                   
               4)    
                   toggle_ksm;;
                   
               5)
                   disable_selinux;;
                        
               q)   
                   break
                   ;;
                *)
                   echo "无效的选项，请重新输入"
                    ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
            
        6)
            bbryj
            ;;
        7)
            curl https://raw.githubusercontent.com/oneclickvirt/backtrace/main/backtrace_install.sh -sSf | bash && backtrace
            ;;
        8)
            bash <(curl -Ls IP.Check.Place)
            ;;
        9)
            lmtjc
            ;;
        10)
            bash <(wget -qO- bash.spiritlhl.net/ecs)
            ;;
        11)
            bash <(curl -sSL https://linuxmirrors.cn/main.sh)
            ;;
        12)
            bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
            ;;
        13)
            if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh fe0808632
            ;;
        14)
            while true
            do
                clear
                echo "提醒：国内服务器请先换源！否则无法安装docker！"
                echo "1. 国内服务器安装1panel"
                echo "2. 海外服务器安装1panel"
                echo "q. 返回上一页"
                read -p "请输入选项: " other_choice
                case $other_choice in
                
               1) 
                   bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
                   curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sh quick_start.sh
                   ;;
                 
               2) 
                   curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sh quick_start.sh
                   ;;
                        
               q)   
                   break
                   ;;
                *)
                   echo "无效的选项，请重新输入"
                    ;;
                esac
                read -p "按回车键继续..."
            done
            ;;
15)
    # 备份配置文件
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo "已备份 /etc/sysctl.conf 为 /etc/sysctl.conf.bak"

    # 删除旧配置
    echo "正在删除旧配置..."
    sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_frto/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_rfc1337/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_sack/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fack/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_window_scaling/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_adv_win_scale/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
    sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.conf
    sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "旧配置已删除。"

    # 添加新配置
    echo "正在添加新配置..."
    cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    echo "新配置已添加。"

    # 检查并安装 sysctl
if ! command -v sysctl &> /dev/null; then
    echo "sysctl 命令未安装，正在自动安装..."
    if command -v apt &> /dev/null; then
        apt update && apt install -y procps
    elif command -v yum &> /dev/null; then
        yum install -y procps-ng
    elif command -v dnf &> /dev/null; then
        dnf install -y procps-ng
    else
        echo "无法自动安装 sysctl，请手动安装 procps 或 procps-ng 包。"
        exit 1
    fi
    echo "sysctl 已安装。"
fi

# 确保 sysctl 在 PATH 中
export PATH=$PATH:/sbin:/usr/sbin

# 再次检查 sysctl 是否存在
if ! command -v sysctl &> /dev/null; then
    echo "错误：sysctl 命令仍未找到，请手动检查系统。"
    exit 1
fi

# 应用配置
echo "正在应用配置..."
if sysctl -p && sysctl --system; then
    echo "配置已成功应用。"
else
    echo "应用配置失败，请检查 /etc/sysctl.conf 文件。"
    exit 1
fi

    echo "TCP 优化完成！"
    ;;
        16)
            docker_install_main
            ;;
        17)
            auto_disk_main
            ;;
        q)
            echo "再见！服务器推荐：www.95vps.com"
            break
            ;;
        *)
            echo "无效的选项，请重新输入"
            ;;
    esac
    read -p "按回车键继续..."
done)
}

# ---------- 顶层入口：直接进入 Linux 工具箱主菜单 ----------
linux_tools_main

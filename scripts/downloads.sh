#!/bin/bash -e

mkdir -p ${DIR}/downloads
cd ${DIR}/downloads

update_git(){
	printf "Updating ${git_project_name}..."
	if [ -f ${git_project_name}/.git/config ] ; then
		cd ${git_project_name}/
		git pull
		git rev-parse HEAD > gitcommithash
		cd -
	else
		git clone ${git_clone_address} ${git_project_name} -b ${git_branch}
	fi
}


git_project_name="ti-linux-kernel-dev"
git_clone_address="https://github.com/RobertCNelson/ti-linux-kernel-dev"
git_branch="ti-linux-xenomai-4.4.y"
update_git

git_project_name="xenomai-3"
git_clone_address="git://git.xenomai.org/xenomai-3.git"
git_branch="stable-3.0.x"
update_git

git_project_name="Bela"
git_clone_address="https://github.com/BelaPlatform/Bela.git"
git_branch="dev-kernel-4.4.y-xenomai-3-support"
update_git

git_project_name="am335x_pru_package"
git_clone_address="https://github.com/giuliomoro/am335x_pru_package.git"
git_branch="master"
update_git

git_project_name="prudebug"
git_clone_address="https://github.com/giuliomoro/prudebug.git"
git_branch="master"
update_git

git_project_name="u-boot"
git_clone_address="https://github.com/u-boot/u-boot"
git_branch="master"
update_git

git_project_name="bb.org-overlays"
git_clone_address="https://github.com/beagleboard/bb.org-overlays.git"
git_branch="master"
update_git

git_project_name="bb.org-dtc"
git_clone_address="https://github.com/RobertCNelson/dtc"
git_branch="dtc-v1.4.4"
update_git

git_project_name="dtb-rebuilder"
git_clone_address="https://github.com/LBDonovan/dtb-rebuilder.git"
git_branch="4.4-ti"
update_git

git_project_name="boot-scripts"
git_clone_address="https://github.com/RobertCNelson/boot-scripts.git"
git_branch="master"
update_git

git_project_name="seasocks"
git_clone_address="https://github.com/mattgodbolt/seasocks.git"
git_branch="master"
update_git

if [ ! -d "clang+llvm-4.0.0-armv7a-linux-gnueabihf" ]; then
	if [ ! -f "clang+llvm-4.0.0-armv7a-linux-gnueabihf.tar.xz" ]; then
		wget "http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-armv7a-linux-gnueabihf.tar.xz"
	fi
	echo "extracting clang"
	tar -xf clang+llvm-4.0.0-armv7a-linux-gnueabihf.tar.xz 
fi

if [ ! -f "setup_7.x" ] ; then
	wget https://deb.nodesource.com/setup_7.x
fi


#!/bin/bash -e
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }

mkdir -p ${DIR}/downloads
cd ${DIR}/downloads

update_git(){
	git_tag=$1
	printf "Updating ${git_project_name}..."
	if [ -f ${git_project_name}/.git/config ] ; then
		cd ${git_project_name}/
		git fetch
		git checkout --force $git_branch
		git pull
		if [ -n "$git_tag" ]
		then
			git branch -D $git_tag || true
			git checkout -b $git_tag $git_tag
		fi
		git rev-parse HEAD > gitcommithash
		cd -
	else
		git clone ${git_clone_address} ${git_project_name} -b ${git_branch}
	fi
}


git_project_name="ti-linux-kernel-dev"
git_clone_address="https://github.com/RobertCNelson/ti-linux-kernel-dev"
git_branch="ti-linux-xenomai-4.19.y"
update_git

git_project_name="xenomai-3"
git_clone_address="git://git.xenomai.org/xenomai-3.git"
git_branch="stable/v3.1.x"
update_git

git_project_name="Bela"
git_clone_address="https://github.com/BelaPlatform/Bela.git"
git_branch="master"
update_git

git_project_name="am335x_pru_package"
git_clone_address="https://github.com/giuliomoro/am335x_pru_package.git"
git_branch="master"
update_git

git_project_name="prudebug"
git_clone_address="https://github.com/giuliomoro/prudebug.git"
git_branch="master"
update_git

git_project_name="Bootloader-Builder"
git_clone_address="https://github.com/giuliomoro/Bootloader-Builder.git"
git_branch="master"
update_git

git_project_name="bb.org-overlays"
git_clone_address="https://github.com/BelaPlatform/bb.org-overlays.git"
git_branch="master"
update_git

git_project_name="BeagleBoard-DeviceTrees"
git_clone_address="https://github.com/beagleboard/BeagleBoard-DeviceTrees/"
git_branch="v4.19.x-ti-overlays"
update_git

git_project_name="seasocks"
git_clone_address="https://github.com/mattgodbolt/seasocks.git"
git_branch="master"
update_git

git_project_name="rtdm_pruss_irq"
git_clone_address="https://github.com/BelaPlatform/rtdm_pruss_irq"
git_branch="master"
update_git

git_project_name="checkinstall"
git_clone_address="https://github.com/giuliomoro/checkinstall"
git_branch="master"
update_git

git_project_name="hvcc"
git_clone_address="https://github.com/giuliomoro/hvcc"
git_branch="master-bela"
update_git

if [ ! -f "setup_10.x" ] ; then
	wget https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_10.x
fi

# get a GCC for cross compiling non-kernel stuff
GCCV=8.3-2019.03
GCC_FOLDER=gcc-arm-$GCCV-x86_64-arm-linux-gnueabihf
if [ ! -d "$GCC_FOLDER" ] ; then
	wget https://developer.arm.com/-/media/Files/downloads/gnu-a/$GCCV/binrel/$GCC_FOLDER.tar.xz
	unxz $GCC_FOLDER.tar.xz
	tar xf $GCC_FOLDER.tar
	echo CC_PREFIX=`pwd`/$GCC_FOLDER/bin/arm-linux-gnueabihf- > CC_PREFIX
fi

rm *.xz *.tar
rm -rf deb
mkdir -p deb && cd deb


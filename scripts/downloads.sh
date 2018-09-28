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
git_branch="ti-linux-xenomai-4.4.y"
update_git

git_project_name="xenomai-3"
git_clone_address="git://git.xenomai.org/xenomai-3.git"
git_branch="stable/v3.0.x"
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

git_project_name="bb.org-dtc"
git_clone_address="https://github.com/RobertCNelson/dtc"
git_branch="dtc-v1.4.4"
update_git

git_project_name="dtb-rebuilder"
git_clone_address="https://github.com/RobertCNelson/dtb-rebuilder.git"
git_branch="4.4-ti"
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
git_clone_address="https://github.com/enzienaudio/hvcc"
git_branch="master"
update_git

if [ ! -f "setup_8.x" ] ; then
	wget https://deb.nodesource.com/setup_8.x
fi

rm -rf deb
mkdir -p deb && cd deb

# get SuperCollider. TODO: track the most recent release
wget "https://github.com/giuliomoro/supercollider/releases/download/3.9dev-Bela-build_20171011/supercollider-bela-xenomai-3_3.9dev-build_20171011_armhf.deb"
wget "https://github.com/giuliomoro/supercollider/releases/download/3.9dev-Bela-build_20171011/sc3-plugins_20180226-1_armhf.deb"


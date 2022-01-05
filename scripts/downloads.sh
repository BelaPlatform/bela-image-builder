#!/bin/bash -e
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }

mkdir -p ${DIR}/downloads
cd ${DIR}/downloads

update_git(){
	git_tag=$1
	printf "Updating ${git_project_name}..."
	if [ -f ${git_project_name}/.git/config ] ; then
		cd ${git_project_name}/
		git fetch --tags ${git_clone_address}
		git checkout --force $git_branch
		# if git_branch does not exist on any remote...
		git branch -a | grep -q "/$git_branch$" || git_tag=$git_branch
		if [ -n "$git_tag" ]
		then
			git checkout -b tmpaaaaaaaaa
			git branch -D $git_tag || true
			git checkout -b $git_tag $git_tag
			git branch -D tmpaaaaaaaaa
		else
			git pull
		fi
		git rev-parse HEAD > gitcommithash
		cd -
	else
		git clone ${git_clone_address} ${git_project_name} -b ${git_branch}
	fi
}


git_project_name="ti-linux-kernel-dev"
git_clone_address="https://github.com/RobertCNelson/ti-linux-kernel-dev"
git_branch="ti-linux-xenomai-4.14.y"
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

git_project_name="BeagleBoard-DeviceTrees"
git_clone_address="https://github.com/beagleboard/BeagleBoard-DeviceTrees/"
git_branch="v4.19.x-ti-overlays"
update_git

git_project_name="seasocks"
git_clone_address="https://github.com/mattgodbolt/seasocks.git"
git_branch="v1.4.4"
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

rm -rf deb
mkdir -p deb && cd deb


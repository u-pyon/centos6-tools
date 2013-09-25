#!/bin/sh


git clone git://github.com/yonchu/tmux-powerline-wrapper.git
git clone git://github.com/yonchu/tmux-powerline.git

# TODO: Setting .tmux

yum -y install fontforge

pushd ~

#: << '#_Ricty_install_failure'
if [ ! -e ./Ricty ]; then
  git clone https://github.com/yascentur/Ricty.git
fi
cd Ricty

if [ ! -e ./Inconsolata.otf ]; then
  wget http://levien.com/type/myfonts/Inconsolata.otf
fi

if [ ! -e ./migu-1m-20121030.zip ]; then
  wget http://iij.dl.sourceforge.jp/mix-mplus-ipa/57240/migu-1m-20121030.zip
fi
unzip migu-1m-20121030.zip


mv ./migu-1m-20121030/migu-1m-regular.ttf .
mv ./migu-1m-20121030/migu-1m-bold.ttf .
# For Abnormal terminated error.
cp ./migu-1m-regular.ttf mig-1m-regularr.ttf
cp ./migu-1m-regular.ttf migu-1m-reguarr.ttf
#sh ricty_generator.sh Inconsolata.otf ./migu-1m-20121030/migu-1m-regular.ttf ./migu-1m-20121030/migu-1m-bold.ttf
sh ricty_generator.sh -l -v auto

if [ ! -d /usr/share/fonts/Ricty ]; then
  mkdir /usr/share/fonts/Ricty
fi
cp -f Ricty*.ttf /usr/share/fonts/Ricty/
fc-cache -vf

popd
#_Ricty_install_failure

# Install ~/.vim/bundle
#git clone https://github.com/Lokaltog/vim-powerline.git vim-powerline

# Add python module
# TODO: Have to cd ~ and mv .ttf and so on
#curl -LO http://peak.telecommunity.com/dist/ez_setup.py
#python ez_setup.py
#easy_install argparse
#fontforge -lang=py -script fontpatcher Ricty-Regular.ttf
#fontforge -lang=py -script fontpatcher Ricty-Bold.ttf
#cp Ricty-Regular-Powerline.ttf /usr/share/fonts
#cp Ricty-Bold-Powerline.ttf /usr/share/fonts
#fc-cache -vf

exit 1

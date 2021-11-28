source $EVANGELIST/_impl/utils.sh

if ! utils::dummy_v1_gt_v2 $(node --version) 'v12.12'
then
  curl -sL install-node.now.sh/lts | sudo -E bash -
fi

nvim +'CocInstall coc-json coc-pyright coc-clangd coc-sh coc-vimlsp'

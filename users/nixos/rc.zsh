#!/usr/bin/env zsh

alias nixsh="env PS1=\"nixsh> \" GIT_WORK_TREE=\"\${NIXOSHOME}\" GIT_DIR=\"\${HOME}/.nixos-home.git\" zsh --no-rcs --no-globalrcs"

# Installation script (zsh) for https://github.com/nxmatic/nixos-home

if [ -z "${NIXOSHOME}" ]; then
    export NIXOSHOME=$(realpath --canonicalize-missing ~/.config/nixos)
fi

setopt aliases

# TODO: giconfigure sparse checkout based on os/flavors

nixsh <<EOF
if [ ! -d "\${GIT_DIR}" ]; then
    mkdir -p \${NIXOSHOME}
    tmpfile=\$(mktemp -d ${NIXOSHOME}/$(basename $0).XXXXX) && trap "rm -fr \$tmpfile" 0

    git clone --quiet --bare https://github.com/nxmatic/nixos-home "\$GIT_DIR" 
    git ls-tree -r HEAD | awk '{print \$NF}' > \$tmpfile/ls-tree
    
    rsync -av --files-from=\${tmpfile}/ls-tree \$GIT_WORK_TREE \${tmpfile} 2>/dev/null || true
    
    (cd \${GIT_WORK_TREE} && xargs rm -f < \${tmpfile}/ls-tree)

    git config status.showUntrackedFiles no
    git checkout
    rsync -av --files-from=\${tmpfile}/ls-tree \$tmpfile \${GIT_WORK_TREE} 2>/dev/null || true
else
    git fetch
fi
EOF

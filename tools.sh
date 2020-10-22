#!/bin/bash
#
# Tools to ease maintainance
#

generate_srcinfo() {
  local vcs_protocols=(
    'bzr://' 'bzr+http'
    'git://' 'git+http'
    'hg://' 'hg+http'
    'svn://' 'svn+http'
  )

  for package in $(ls); do
    if [ ! -d "$package" ]; then
      continue
    elif [ ! -e "$package/PKGBUILD" ]; then
      continue
    fi

    cd "$package"

    local srcinfo=$(makepkg --printsrcinfo)
    local has_vcs_source=0

    for protocol in "${vcs_protocols[@]}"; do
      if echo "$srcinfo" | grep "$protocol" > /dev/null ; then
        # dont skip vcs sources that point to a specific commit
        if ! echo "$srcinfo" | grep "$protocol" | grep "#" > /dev/null ; then
          # dont skip if already has a .SRCINFO
          if [ ! -e ".SRCINFO" ]; then
            has_vcs_source=1
            break
          fi
        fi
      fi
    done

    if [ $has_vcs_source -ne 1 ]; then
      echo "$srcinfo" > .SRCINFO
      echo "$package generated"
    else
      echo "$package skip"
    fi

    cd ../
  done
}

print_no_srcinfo() {
  for package in $(ls); do
    if [ -e "$package/PKGBUILD" ]; then
      if [ ! -e "$package/.SRCINFO" ]; then
        echo "$package"
      fi
    fi
  done
}

case $1 in
  'mksrcinfo' )
    generate_srcinfo
    exit
    ;;
  'nosrcinfo' )
    print_no_srcinfo
    exit
    ;;
  * )
    echo "Helper script."
    echo ""
    echo "COMMANDS"
    echo "  mksrcinfo    Generate .SRCINFO for all applicable packages"
    echo "               skipping does that target a VCS."
    echo ""
    echo "  nosrcinfo    Display packages without a .SRCINFO file"
    echo ""
    echo "  help         print this help"
    exit
    ;;
esac

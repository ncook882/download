#!/bin/bash
codes_dependencies common-test
install -m 555 /dev/stdin "${codes_dir[bin]}"/rscode-test <<EOF
#!/bin/bash
# POSIT: codes.sh sets locally-scoped version var
echo "RPM_CODE_TEST_VERSION=$version"
EOF
install_source_bashrc
# mock
codes_python_lib_dir() {
    echo /home/vagrant/.pyenv/versions/py2/lib/python2.7/site-packages
}
_xyz=$(pyenv prefix)/xyz
mkdir -p "$_xyz"
my_sh=${codes_dir[bashrc_d]}/my.sh
echo echo PASS > "$my_sh"
rpm_code_build_include_add "$my_sh"
echo pass > my.py
codes_python_lib_copy my.py
# otherwise directories are owned by root
echo PASS > "$_xyz/PASS"
_fail="$(pyenv prefix)/FAIL"
mkdir -p "$_fail"
rpm_code_build_include_add "$_xyz"
rscode-test

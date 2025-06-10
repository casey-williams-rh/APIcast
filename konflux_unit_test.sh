#!/bin/bash

# ARG: Set build-time variables
export OPENRESTY_RPM_VERSION="1.21.4-1.el8"
export LUAROCKS_VERSION="2.3.0"
export JAEGERTRACING_CPP_CLIENT_RPM_VERSION="0.3.1-13.el8"

# The LABEL instructions are metadata for the container image and do not have a direct shell command equivalent.
# They provide information about the image.

# WORKDIR: Set the working directory for subsequent commands
mkdir -p /tmp
cd /tmp

# ENV: Set environment variables
export AUTO_UPDATE_INTERVAL=0
# The $HOME is not set by default, but some applications needs this variable
export HOME=/opt/app-root/src
export PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH
export PLATFORM="el8"

# RUN: Update the system
microdnf update

# RUN: Install 'yum-utils'
microdnf install -y 'yum-utils'

# RUN: Add a new repository
yum-config-manager --add-repo http://packages.dev.3sca.net/dev_packages_3sca_net.repo

# RUN: Install packages and create home directory
export PKGS="openresty-resty-${OPENRESTY_RPM_VERSION} openresty-opentelemetry-${OPENRESTY_RPM_VERSION} openssl-devel git gcc make curl tar openresty-opentracing-${OPENRESTY_RPM_VERSION} openresty-${OPENRESTY_RPM_VERSION} luarocks-${LUAROCKS_VERSION} opentracing-cpp-devel-1.3.0 libopentracing-cpp1-1.3.0 jaegertracing-cpp-client-${JAEGERTRACING_CPP_CLIENT_RPM_VERSION}"
mkdir -p "$HOME"
microdnf -y --setopt=tsflags=nodocs install $PKGS
rpm -V $PKGS
microdnf clean all -y

# COPY: These commands would copy files from the build context into the container.
# In a standalone script, we'll represent them as creating placeholder files.
touch site_config.lua
touch config-a.lua config-b.lua # Placeholder for config-*.lua
cp site_config.lua /usr/share/lua/5.1/luarocks/site_config.lua
cp config-*.lua /usr/local/openresty/config-5.1.lua

# ENV: Set more environment variables for the build process
export PATH="./lua_modules/bin:/usr/local/openresty/luajit/bin/:${PATH}"
export LUA_PATH="./lua_modules/share/lua/5.1/?.lua;./lua_modules/share/lua/5.1/?/init.lua;/usr/lib64/lua/5.1/?.lua;/usr/share/lua/5.1/?.lua"
export LUA_CPATH="./lua_modules/lib/lua/5.1/?.so;;"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/app-root/lib"

# RUN: Install Lua rocks
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/pintsized/lua-resty-http-0.17.1-0.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/kikito/router-2.1-0.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/kikito/inspect-3.1.1-0.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/cdbattags/lua-resty-jwt-0.2.0-0.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/3scale/lua-resty-url-0.3.5-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/3scale/lua-resty-env-0.4.0-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/3scale/liquid-0.2.0-2.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/tieske/date-2.2-2.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/tieske/penlight-1.13.1-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/mpeterv/argparse-0.6.0-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/3scale/lua-resty-execvp-0.1.1-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/hisham/luafilesystem-1.8.0-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/3scale/lua-resty-jit-uuid-0.0.7-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/knyar/nginx-lua-prometheus-0.20181120-2.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/hamish/lua-resty-iputils-0.3.0-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/golgote/net-url-0.9-1.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/membphis/lua-resty-ipmatcher-0.6.1-0.src.rock
luarocks install --deps-mode=none --tree /usr/local https://luarocks.org/manifests/fffonion/lua-resty-openssl-1.5.1-1.src.rock

# RUN: Clean up build dependencies
microdnf -y remove yum-utils openssl-devel perl-Git-* git annobin-* gcc-plugin-annobin-* gcc luarocks
rm -rf /var/cache/yum
microdnf clean all -y
rm -rf ./*

# COPY: This would copy the application source code into the container.
# We'll simulate this by creating the directory.
mkdir -p /opt/app-root/src/

# RUN: Create directories, add a user, and set up symbolic links and permissions
mkdir -p /opt/app-root/src/logs
useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin -c "Default Application User" default
rm -r /usr/local/openresty/nginx/logs
ln -s /opt/app-root/src/logs /usr/local/openresty/nginx/logs
ln -s /dev/stdout /opt/app-root/src/logs/access.log
ln -s /dev/stderr /opt/app-root/src/logs/error.log
mkdir -p /usr/local/share/lua/
chmod g+w /usr/local/share/lua/
mkdir -p /usr/local/openresty/nginx/{client_body_temp,fastcgi_temp,proxy_temp,scgi_temp,uwsgi_temp}
chown -R 1001:0 /opt/app-root /usr/local/share/lua/ /usr/local/openresty/nginx/{client_body_temp,fastcgi_temp,proxy_temp,scgi_temp,uwsgi_temp}

# RUN: Create more symbolic links and set permissions
ln --verbose --symbolic /opt/app-root/src/bin /opt/app-root/bin
ln --verbose --symbolic /opt/app-root/src/http.d /opt/app-root/http.d
ln --verbose --symbolic --force /etc/ssl/certs/ca-bundle.crt "/opt/app-root/src/conf"
chmod --verbose g+w "${HOME}" "${HOME}"/* "${HOME}/http.d"
chown -R 1001:0 /opt/app-root

# RUN: Create application-specific symbolic links
ln --verbose --symbolic /opt/app-root/src /opt/app-root/app
ln --verbose --symbolic /opt/app-root/bin /opt/app-root/scripts

# WORKDIR: Change the working directory
cd /opt/app-root/app

# USER: Switch the user. Subsequent commands would be run as user 1001.
# This is represented in a shell script by using 'su' or 'sudo -u',
# but for simplicity, we'll just note it as a comment.
# The rest of the script logic would be executed by user 1001.

# ENV: Set final environment variables for the runtime
export LUA_CPATH="./?.so;/usr/lib64/lua/5.1/?.so;/usr/lib64/lua/5.1/loadall.so;/usr/local/lib64/lua/5.1/?.so"
export LUA_PATH="/usr/lib64/lua/5.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/*/?.lua;;"

# WORKDIR: Change the final working directory
cd /opt/app-root

# ENTRYPOINT and CMD: Define the command to execute when the container starts.
# This translates to running the 'container-entrypoint' with 'scripts/run' as an argument.
echo "Container would now execute: container-entrypoint scripts/run"
# Example of how it might be executed:
# /usr/bin/container-entrypoint scripts/run


docker ls
# Step 2: Inspect the container to get its exit code
# The '{{.State.ExitCode}}' format string extracts just the number.
exit_code=$(docker inspect my-task-container --format='{{.State.ExitCode}}')

# Step 3: Check the exit code in a script
if [ "$exit_code" -eq 0 ]; then
  echo "Container 'my-task-container' ran safely and completed successfully."
else
  echo "Error: Container 'my-task-container' exited with code $exit_code."
  echo "--- Displaying container logs ---"
  docker logs my-task-container
fi

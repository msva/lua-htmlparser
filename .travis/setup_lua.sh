#! /bin/bash
# vim: ft=sh sw=2 ts=2

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.x" or "luajit".
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -eufo pipefail

LUAJIT_VERSION="2.0.5"
LUAJIT_BASE="LuaJIT-${LUAJIT_VERSION}"

# shellcheck disable=SC1091
source .travis/platform.sh

LUA_HOME_DIR="${TRAVIS_BUILD_DIR}/install/lua"

LR_HOME_DIR="${TRAVIS_BUILD_DIR}/install/luarocks"

mkdir "${HOME}/.lua" -p

LUAJIT="no"

if [ "${LUA:0:6}" == "luajit" ]; then
	LUAJIT="yes"
fi

mkdir -p "${LUA_HOME_DIR}"

if [ "${LUAJIT}" == "yes" ]; then
	if [ "${LUA}" == "luajit" ]; then
		curl -LSs "https://github.com/LuaJIT/LuaJIT/archive/v${LUAJIT_VERSION}.tar.gz" | tar xz
	else
		LJ_V="${LUA##luajit}"
		[[ -z "${LJ_V}" ]] && LJ_V="2.0"
		git clone https://github.com/LuaJIT/LuaJIT.git -b "v${LJ_V}" "${LUAJIT_BASE}"
	fi

	cd "${LUAJIT_BASE}"

	if [ "${LUA}" == "luajit2.1" ]; then
		# force the INSTALL_TNAME to be luajit
		perl -i -pe 's/INSTALL_TNAME=.+/INSTALL_TNAME= luajit/' Makefile
	fi

	make && make install PREFIX="${LUA_HOME_DIR}"

	ln -s "${LUA_HOME_DIR}/bin/luajit" "${HOME}/.lua/luajit"
	ln -s "${LUA_HOME_DIR}/bin/luajit" "${HOME}/.lua/lua"
else
	if [ "${LUA}" == "lua5.1" ]; then
		suff="ftp/lua-5.1.5.tar.gz"
	elif [ "${LUA}" == "lua5.2" ]; then
		suff="ftp/lua-5.2.4.tar.gz"
	elif [ "${LUA}" == "lua5.3" ]; then
		suff="ftp/lua-5.3.5.tar.gz"
	elif [ "${LUA}" == "lua5.4" ]; then
		suff="work/lua-5.4.0-alpha-rc2.tar.gz"
	fi

	mkdir lua_build -p
	curl -LSs "http://www.lua.org/${suff}" | tar xz -C lua_build --strip-components=1
	cd lua_build

	# Build Lua without backwards compatibility for testing
	perl -i -pe 's/-DLUA_COMPAT_(ALL|5_[0-9])//' src/Makefile
	make "${PLATFORM}"
	make INSTALL_TOP="${LUA_HOME_DIR}" install

	ln -s "${LUA_HOME_DIR}/bin/lua" "${HOME}/.lua/lua"
	ln -s "${LUA_HOME_DIR}/bin/luac" "${HOME}/.lua/luac"
fi

cd "${TRAVIS_BUILD_DIR}"

lua -v

LUAROCKS_BASE=luarocks-$LUAROCKS

curl -LSs https://luarocks.github.io/luarocks/releases/"${LUAROCKS_BASE}".tar.gz | tar xz

cd "${LUAROCKS_BASE}"

if [ "${LUA}" == "luajit" ]; then
	export LUA_INCDIR="${LUA_HOME_DIR}/include/luajit-2.0"
elif [ "${LUA}" == "luajit2.0" ]; then
	export LUA_INCDIR="${LUA_HOME_DIR}/include/luajit-2.0"
elif [ "${LUA}" == "luajit2.1" ]; then
	export LUA_INCDIR="${LUA_HOME_DIR}/include/luajit-2.1"
fi

./configure --with-lua="${LUA_HOME_DIR}" --prefix="${LR_HOME_DIR}"
make build && make install

ln -s "${LR_HOME_DIR}/bin/luarocks" "${HOME}/.lua/luarocks"

cd "${TRAVIS_BUILD_DIR}"

luarocks --version

rm -rf "${LUAROCKS_BASE}"

if [ "${LUAJIT}" == "yes" ]; then
	rm -rf "${LUAJIT_BASE}"
else
	rm -rf lua_build
fi

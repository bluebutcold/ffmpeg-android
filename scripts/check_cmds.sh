#!/bin/bash

# Ensure temp directory exists
mkdir -p "$ROOT_DIR/temp"

check() {
	for cmd in "$@"; do
		printf "checking for %s... " "$cmd"
		sleep 0.01
		if command -v "$cmd" >/dev/null 2>&1; then
			echo "found"
		else
			echo "not found"
			echo "Error: '$cmd' is missing. Aborting."
			exit 1
		fi
	done
}

# Detect a working C compiler
detect_host_cc() {
	for cc in gcc clang cc; do
		cc_path=$(command -v "$cc" 2>/dev/null)
		if [[ -n "$cc_path" ]]; then
			test_file="$ROOT_DIR/temp/test.c"
			test_bin="$ROOT_DIR/temp/test_cc"
			echo 'int main() { return 0; }' >"$test_file"
			if "$cc_path" "$test_file" -o "$test_bin" &>/dev/null; then
				"$test_bin" &>/dev/null
				if [[ $? -eq 0 ]]; then
					HOST_CC="$cc_path"
					rm -f "$test_file" "$test_bin"
					echo "Detected working Host C compiler: $HOST_CC"
					return
				fi
			fi
		fi
	done
	echo "No working C compiler detected. Aborting."
	exit 1
}

# Detect a working C++ compiler
detect_host_cxx() {
	for cxx in g++ clang++ c++; do
		cxx_path=$(command -v "$cxx" 2>/dev/null)
		if [[ -n "$cxx_path" ]]; then
			test_file="$ROOT_DIR/temp/test.cpp"
			test_bin="$ROOT_DIR/temp/test_cxx"
			echo 'int main() { return 0; }' >"$test_file"
			if "$cxx_path" "$test_file" -o "$test_bin" &>/dev/null; then
				"$test_bin" &>/dev/null
				if [[ $? -eq 0 ]]; then
					HOST_CXX="$cxx_path"
					rm -f "$test_file" "$test_bin"
					echo "Detected working Host C++ compiler: $HOST_CXX"
					return
				fi
			fi
		fi
	done
	echo "No working C++ compiler detected. Aborting."
	exit 1
}

check which curl wget tar zip sed meson \
	make autopoint cmake ninja autoconf automake libtool pkg-config makeinfo \
	gettext gperf bison flex git xz unzip file find cp mv rm ln svn nasm yasm

#[ -z "$FFMPEG_STATIC" ] && check ruby
#[ "$ARCH" != "riscv64" ] && check rustc cargo

detect_host_cc
detect_host_cxx

export HOST_CC HOST_CXX

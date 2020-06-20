#!/usr/bin/env bash
mkdir -p ~/klee_build
mkdir -p ~/klee_build/stp-2.3.3/build

( cd ~/klee_build ; zcat /vagrant/chains/stp.2.3.3.tar.gz | tar -xpf - )
( cd ~/klee_build/stp-2.3.3/build; cmake ..; make; sudo make install; )

( cd ~/klee_build; zcat /vagrant/chains/klee_uclibc_v1.2.tar.gz | tar -xvpf - )
( cd ~/klee_build/klee-uclibc-klee_uclibc_v1.2/; ./configure --make-llvm-lib --with-llvm-config=/usr/bin/llvm-config-6.0 )
( cd ~/klee_build/klee-uclibc-klee_uclibc_v1.2/; make -j2 )

( cd ~/klee_build; zcat /vagrant/chains/klee_2.1.tar.gz  | tar -xvpf - )
mkdir -p ~/klee_build/klee-2.1/build
(cd ~/klee_build/klee-2.1/build; cmake \
  -DENABLE_SOLVER_STP=ON \
  -DENABLE_POSIX_RUNTIME=ON \
  -DENABLE_KLEE_UCLIBC=ON \
  -DKLEE_UCLIBC_PATH=/home/vagrant/klee_build/klee-uclibc-klee_uclibc_v1.2/ \
  -DENABLE_UNIT_TESTS=OFF \
  -DENABLE_SYSTEM_TESTS=OFF \
  -DLLVM_CONFIG_BINARY=/usr/bin/llvm-config-6.0 \
  -DLLVMCC=/usr/bin/clang-6.0 \
  -DLLVMCXX=/usr/bin/clang++-6.0 \
  .. )

(cd ~/klee_build/klee-2.1/build; make; sudo make install )

python=python3

clean: ; rm -rf *.log
clobber: clean;
	-$(MAKE) box-remove
	-rm -rf artifact artifact.tar.gz
	-rm -rf .db
results:; mkdir -p results

artifact.tar.gz: Vagrantfile Makefile
	rm -rf artifact && mkdir -p artifact/chains
	cp README.md artifact/README.txt
	cp -r README.md Makefile Vagrantfile taints.tar.gz etc/setup_llvm_clang.sh  etc/json-c-0.13.1-20180305.tar.gz etc/afl-2.52b.tgz artifact/chains
	git clone https://github.com/uds-se/pFuzzer/ artifact/chains/src
	cp etc/tiny.c artifact/chains/src/afl/tinyc/tiny.c
	cp etc/tiny.c artifact/chains/src/afl/tinyc/eval/tiny.c
	cp etc/tiny.c artifact/chains/src/klee/tinyc/tiny.c
	cp etc/tiny.c artifact/chains/src/klee/tinyc/eval/tiny.c
	cp etc/tiny.c artifact/chains/src/pfuzzer/samples/tinyc/tiny.c
	# cat etc/patch.patch | (cd artifact/chains/src/; patch -p1 )
	cp etc/patch.patch artifact/chains/
	mkdir -p  artifact/chains/src/pfuzzer/modules/trace-taint/sources/dependencies/
	cp etc/*.jar artifact/chains/src/pfuzzer/modules/trace-taint/sources/dependencies/
	cp -r Vagrantfile artifact/
	tar -cf artifact1.tar artifact
	gzip artifact1.tar
	mv artifact1.tar.gz artifact.tar.gz

ARTIFACT=artifact.tar.gz

# PACKAGING
# https://github.com/json-c/json-c/archive/json-c-0.13.1-20180305.tar.gz
box-create: chains.box
chains.box: $(ARTIFACT)
	cd artifact && vagrant up
	cd artifact && vagrant ssh -c 'cd /vagrant; tar -cpf ~/chains.tar chains/src chains/Makefile chains/README.md; cd ~/; tar -xpf ~/chains.tar; rm -f ~/chains.tar'
	cd artifact && vagrant ssh -c 'cd ~/ && zcat /vagrant/chains/taints.tar.gz | tar -xpf -'
	cd artifact && vagrant ssh -c 'cd ~/ && echo export PATH="/usr/local/opt/llvm@4/bin:/usr/local/bin:$$PATH" > ~/.init.sh'
	cat toolchains.tar.gz.1 toolchains.tar.gz.2 > artifact/chains/toolchains.tar.gz
	cd artifact && vagrant ssh -c 'cd ~/taints/ && cp /vagrant/chains/setup_llvm_clang.sh ./scripts/ && ./scripts/setup_llvm_clang.sh'
	# cp artifact/chains/toolchain.tar.gz .
	cd artifact && vagrant ssh -c 'mkdir -p ~/chains/src/programs'
	cd artifact && vagrant ssh -c 'cd ~/chains/src/programs; zcat /vagrant/chains/afl-2.52b.tgz | tar -xvpf -'
	cd artifact && vagrant ssh -c 'cd ~/chains/src/programs/afl-2.52b/ && make'
	cd artifact && vagrant ssh -c 'zcat /vagrant/chains/json-c-0.13.1-20180305.tar.gz | tar -xvpf -'
	cd artifact && vagrant ssh -c 'cd /home/vagrant/json-c-json-c-0.13.1-20180305 && ./configure --prefix=/usr && make'
	cd artifact && vagrant ssh -c 'cd /home/vagrant/json-c-json-c-0.13.1-20180305 && sudo make install'
	cd artifact && vagrant ssh -c 'cd /home/vagrant/ && rm -rf json-c-json-c-0.13.1-20180305'
	cd artifact && vagrant ssh -c 'cd ~/taints/ && source ~/.init.sh && meson build/debug --prefix="$$(pwd)/install"'
	cd artifact && vagrant ssh -c 'cd ~/taints/ && source ~/.init.sh && ninja -C build/debug install'
	cd artifact && vagrant package --output ../chains1.box --vagrantfile ../Vagrantfile.new
	mv chains1.box chains.box

box-hash:
	md5sum chains.box

box-add: #| chains.box
	-vagrant destroy $$(vagrant global-status | grep chains | sed -e 's# .*##g')
	rm -rf vtest && mkdir -p vtest && cp chains.box vtest
	cd vtest && vagrant box add chains ./chains.box
	cd vtest && vagrant init chains
	cd vtest && vagrant up

box-status:
	vagrant global-status | grep chains
	vagrant box list | grep chains

box-remove:
	-vagrant destroy $$(vagrant global-status | grep chains | sed -e 's# .*##g')
	vagrant box remove chains

show-ports:
	 sudo netstat -ln --program | grep 8888

box-connect1:
	cd artifact; vagrant up; vagrant ssh
box-connect2:
	cd vtest; vagrant ssh

rsync:
	rsync -avz  --partial-dir=.rsync-partial --progress --rsh="ssh" chains.box shuttle:/scratch/rahul/vm/



VM=

vm-list:
	VBoxManage list vms

vm-remove:
	VBoxManage startvm $(VM)  --type emergencystop
	VBoxManage unregistervm $(VM) -delete


# Created by Ed Nutting <ed.nutting.2014@my.bristol.ac.uk>
# Version 1 - 2016-10-05
#
#	Downloads and builds PDT and TAU tools for Ubuntu Linux.
#	Also does a basic setup of the HPC coursework.
#	    * Clones the University of Bristol HPC Coursework sample repository, 
#	    * Corrects the makefile, 
#	    * Builds and executes the sample program using TAU
#	    * Executes pprof to analyse the results
#
#
#
# 			Copyright (C) 2016 Ed Nutting
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.
# 
#    You can contact the author, Ed Nutting, via en14078@my.bristol.ac.uk


# ================= READ THIS STUFF =================
#
# FAIR WARNING:
#	This script deletes files and directories that it thinks it may have previously created.
#	Namely: 
#		~/pdt
#		~/tau
#		~/Documents/UoB-HPC-LBM-2016
#
#	If you already have files in those folders, don't run this script! Because they're going to be deleted. 
#	Back them up first then run this script.
#
#
# How to use:
#	1. Save file into your home directory (cd ~/)
# 	2. chmod +x ~/hpc_configure.sh
#	3. ~/hpc_configure.sh
#	4. (First time only!) y - to modify path
# 	5. Restart your command prompt (bash)
#	6. It should just work now. 
#
# This script can safely be run multiple times
#	- Remember to answer "n" to the PATH update bit
#	- It will delete all previously created files, so if you make changes then re-run this script, 
#	  you'll lose the changes.
#
# Requirements:
#	- The script makes sure your system is up to date and has all the necessary tools installed (see System Setup section)
# 	- You may need to type in your password for the sudo apt-get bits ;) )
# 	- You'll need an internet connection - a fast one! (Total downloads are >600MB)

echo "    PDT/TAU/HPC Configurer
    ------------------------
    Copyright (C) 2016 Ed Nutting
    This script comes with ABSOLUTELY NO WARRANTY;
    This is free software, and you are welcome to redistribute it
under certain conditions; See top of script for license details.

"


read -n1 -p "Have you checked the list of files to be DELETED? [y,n]" doit 
case $doit in  
  y|Y) 
	echo
	echo "Good. Then let's proceed..."

	# ======== System Setup ========
	echo "======== System Setup ========"
	sudo apt-get update			# A good idea to do this
	sudo apt-get dist-upgrade		# A good idea to do this
	sudo apt-get install gcc		# Required by PDT/TAU
	sudo apt-get install g++		# Required by PDT/TAU
	sudo apt-get install zip unzip gzip	# Required by PDT/TAU
	sudo apt-get install tar 		# Required by this script
	sudo apt-get install git		# Required by this script
	sudo apt-get install sed		# Required by this script

	# ======== PDT Setup ========
	echo "======== PDT Setup ========"
	cd ~/
	rm -f pdt.tar.gz
	wget http://tau.uoregon.edu/pdt.tar.gz
	rm -rf ~/pdt
	mkdir ~/pdt
	cd ~/pdt
	tar -xf ~/pdt.tar.gz
	cp -r ~/pdt/pdtoolkit-3.22.1/* ~/pdt
	rm -rf ~/pdt/pdtoolkit-3.22.1
	cd ~/pdt
	./configure -GNU
	make
	make install


	# ======== TAU Setup ========
	echo "======== TAU Setup ========"
	cd ~/
	rm -f tau.tgz
	wget http://tau.uoregon.edu/tau.tgz
	rm -rf ~/tau
	mkdir ~/tau
	cd ~/tau
	tar -xf ~/tau.tgz
	cp -r ~/tau/tau-2.25.2/* ~/tau
	rm -rf ~/tau/tau-2.25.2
	./configure -cc=gcc -c++=g++ -pdt="$HOME/pdt"
	make install
	
	# ======== Optionally Configure Environemnt ========
	echo "======== Environemnt Setup ========"

	read -n1 -p "Update Environemnt (i.e. add update commands to ~/.bashrc)? (Only do this once!) [y,n]" doit 
	case $doit in  
	  y|Y) 
		# ======== Only run once! ========

		echo Original path was\:
		echo $PATH

		# Add PDT to PATH (to bash setup so the change is added every time you open a bash prompt)
		echo "export PATH=\$HOME/pdt/x86_64/bin:\$PATH" >> ~/.bashrc
		# Add TAU to PATH (to bash setup so the change is added every time you open a bash prompt)
		echo "export PATH=\$HOME/tau/x86_64/bin:\$PATH" >> ~/.bashrc
		# Add TAU_MAKEFILE setup
		echo "export TAU_MAKEFILE=\$HOME/tau/x86_64/lib/Makefile.tau-pdt" >> ~/.bashrc

		echo PATH updated to\:
		echo $PATH
	 ;; 
	  n|N) 
		echo
		echo PATH not updated. ;; 
	  *) 
		echo
		echo That wasn\'t an option. Not update PATH. Next stage may fail if you haven\'t updated PATH at least once before. ;; 
	esac

	# Always add PDT and TAU to current path because "stupid user syndrome" - the changes to PATH below disappear as soon as this script exits
	export PATH=$HOME/pdt/x86_64/bin:$PATH
	export PATH=$HOME/tau/x86_64/bin:$PATH
	# Same reason as before
	export TAU_MAKEFILE=$HOME/tau/x86_64/lib/Makefile.tau-pdt 

	# ======== HPC basic coursework setup ========
	echo "======== Basic HPC Coursework Setup ========"
	cd ~/Documents
	# Clean
	rm -rf ./UoB-HPC-LBM-2016
	# Clone
	git clone https://github.com/UoB-HPC/UoB-HPC-LBM-2016.git
	cd ./UoB-HPC-LBM-2016
	# Bug fix the makefile (shift position of -lm option for linking the Math library)
	sed -i -e 's/ -lm//g' ./Makefile
	sed -i -e 's/$@/\$@ -lm/g' ./Makefile
	# Modify makefile to use TAU compiler
	sed -i -e 's/gcc/tau_cc.sh/g' ./Makefile
	# Make
	make
	# Run
	./d2q9-bgk.exe input_128x128.params obstacles_128x128.dat 
	# View results
	pprof
 ;;
*)
	echo 
	echo "Then you're rushing this process - you should be more careful. Read the top of the script to make sure you're not about to LOSE FILES!!!"
esac

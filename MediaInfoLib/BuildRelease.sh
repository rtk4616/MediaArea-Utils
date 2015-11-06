# MediaInfoLib/Release/BuildRelease.sh
# Build a release of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_mil () {

    cd "$MIL_tmp"

    # Clean up
    $SSHP "test -d $MacWDir || mkdir $MacWDir ;
            cd $MacWDir ;
            rm -fr MediaInfo_DLL*"

    echo
    echo "Compile MIL for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$MacWDir/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz

            #cd MediaInfo_DLL_${Version_new}_GNU_FromSource ;
    $SSHP "cd $MacWDir ;
            tar xf MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_DLL_GNU_FromSource ;
            MediaInfoLib/Project/Mac/build_SO.sh ;
            $KeyChain ;
            cd MediaInfoLib/Project/Mac ;
            ./mktarball.sh ${Version_new}"

    if ! b.opt.has_flag? --snapshot; then
        $SSHP "cd $MacWDir ;
                test -d dylib_for_xcode || mkdir dylib_for_xcode ;
                rm -fr dylib_for_xcode/* ;
                cp MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz dylib_for_xcode"
    fi

    scp -P $MacSSHPort $MacSSHUser@$MacIP:$MacWDir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 "$MILB_dir"
    scp -P $MacSSHPort $MacSSHUser@$MacIP:$MacWDir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz "$MILB_dir"

}

function _mac () {

    # This function test the success of the compilation by testing
    # size and multiarch. If fail, retry to compile up to 3 times.

    local SSHP NbTry Try MultiArch

    # SSH prefix
    SSHP="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    NbTry=3

    cd "$MIL_tmp"

    MultiArch=0
    Try=0
    touch "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2
    until [ `ls -l "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq $NbTry ]; do
        if b.opt.has_flag? --log; then
            _mac_mil >> "$Log"/mac.log 2>&1
        else
            _mac_mil
        fi
        # Return 1 if MIL is compiled for i386 and x86_64,
        # 0 otherwise
        #MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file $MacWDir/MediaInfo_DLL_${Version_new}_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file $MacWDir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        Try=$(($Try + 1))
    done

    # Send a mail if the build fail
    if [ `ls -l "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -lt 4000000 ] || [ $MultiArch -eq 0 ]; then
        xz -9e $Log/mac.log
        if ! [ -z "$MailCC" ]; then
            echo "The log is http://url/$Log/mac.log" | mailx -s "[BR.sh mac] Problem building MIL" -a $Log/mac.log -c "$MailCC" $Mail
        else
            echo "The log is http://url/$Log/mac.log" | mailx -s "[BR.sh mac] Problem building MIL" -a $Log/mac.log $Mail
        fi
    fi

}

function _windows () {

    local sp RWDir

    # SSH prefix
    SSHP="ssh -x -p $WinSSHPort $WinSSHUser@$WinIP"
    RWDir="c:/Users/almin"

    cd "$MIL_tmp"

    # Clean up
    $SSHP "c: & chdir $RWDir & rmdir /S /Q build"
    $SSHP "c: & chdir $RWDir & md build"

    echo
    echo "Compile MIL for windows..."
    echo

}

function _obs () {

    local OBS_Package="$OBS_Project/MediaInfoLib"

    cd "$MIL_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_Package

    # Clean up
    rm -f $OBS_Package/*

    cp prepare_source/archives/libmediainfo_${Version_new}.tar.xz $OBS_Package
    cp prepare_source/archives/libmediainfo_${Version_new}.tar.gz $OBS_Package

    #cp prepare_source/MIL/MediaInfoLib_${Version_new}/Project/GNU/libmediainfo.spec $OBS_Package
    #cp prepare_source/MIL/MediaInfoLib_${Version_new}/Project/GNU/libmediainfo.dsc $OBS_Package/libmediainfo_${Version_new}.dsc
    cp prepare_source/MIL/MediaInfoLib/Project/GNU/libmediainfo.spec $OBS_Package
    cp prepare_source/MIL/MediaInfoLib/Project/GNU/libmediainfo.dsc $OBS_Package/libmediainfo_${Version_new}.dsc
    update_DSC "$MIL_tmp"/$OBS_Package libmediainfo_${Version_new}.tar.xz libmediainfo_${Version_new}.dsc

    cd $OBS_Package
    osc addremove *
    osc commit -n

}

function _obs_deb () {

    # This function build the source on OBS for a specific debian
    # version.

    local debVersion="$1" Comp="$2"
    local OBS_Package="$OBS_Project/MediaInfoLib_$debVersion"

    cd "$MIL_tmp"

    echo
    echo "OBS for $OBS_Package, initialize files..."
    echo

    osc checkout $OBS_Package

    # Clean up
    rm -f $OBS_Package/*

    cp prepare_source/archives/libmediainfo_${Version_new}.tar.$Comp $OBS_Package
    cd $OBS_Package
    tar xf libmediainfo_${Version_new}.tar.$Comp
    rm -fr MediaInfoLib/debian
    mv MediaInfoLib/Project/OBS/${debVersion}.debian MediaInfoLib/debian
    if [ "$Comp" = "xz" ]; then
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libmediainfo_${Version_new}.tar.xz MediaInfoLib)
    elif [ "$Comp" = "gz" ]; then
        (GZIP=-9 tar -cz --owner=root --group=root -f libmediainfo_${Version_new}.tar.gz MediaInfoLib)
    fi
    rm -fr MediaInfoLib
    cd ../..

    #cp prepare_source/MIL/MediaInfoLib_${Version_new}/Project/OBS/${debVersion}.dsc $OBS_Package/libmediainfo_${Version_new}.dsc
    cp prepare_source/MIL/MediaInfoLib/Project/OBS/${debVersion}.dsc $OBS_Package/libmediainfo_${Version_new}.dsc
    update_DSC "$MIL_tmp"/$OBS_Package libmediainfo_${Version_new}.tar.$Comp libmediainfo_${Version_new}.dsc

    cd $OBS_Package
    osc addremove *
    osc commit -n

}

function _linux () {

    if b.opt.has_flag? --log; then
        _obs > "$Log"/linux.log 2>&1
        _obs_deb deb6 gz >> "$Log"/linux.log 2>&1
    else
        _obs
        _obs_deb deb6 gz
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
    fi

    cd $(b.get bang.working_dir)
    python update_Linux_DB.py $OBS_Project MediaInfoLib $Version_new "$MILB_dir" > "$Log"/obs_python.log 2>&1 &
    sleep 10
    python update_Linux_DB.py $OBS_Project MediaInfoLib_deb6 $Version_new "$MILB_dir" > "$Log"/obs_python_deb6.log 2>&1 &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    local MILB_dir="$WDir"/binary/libmediainfo0/$subDir
    local MILS_dir="$WDir"/source/libmediainfo/$subDir
    local MIL_tmp="$WDir"/tmp/libmediainfo/$subDir

    echo
    echo Clean up...
    echo

    rm -fr "$MILB_dir"
    rm -fr "$MILS_dir"
    rm -fr "$MIL_tmp"

    mkdir -p "$MILB_dir"
    mkdir -p "$MILS_dir"
    mkdir -p "$MIL_tmp"

    cd "$MIL_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$SDir" "$MIL_tmp"/upgrade_version/MediaInfoLib
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -sp "$MIL_tmp"/upgrade_version/MediaInfoLib
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -wp "$MIL_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # TODO: final version = remove -nc
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mil -v $Version_new -wp "$MIL_tmp"/prepare_source -sp "$MIL_tmp"/upgrade_version/MediaInfoLib $PSTarget -nc

    if [ "$Target" = "mac" ]; then
        _mac
        mv "$MIL_tmp"/prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MILB_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _windows > "$Log"/windows.log 2>&1
        else
            echo _windows
        fi
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}_AllInclusive.7z "$MILS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        _linux
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}.* "$MILS_dir"
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux
            _mac
            echo _windows > "$Log"/windows.log 2>&1
        else
            _linux
            _mac
            echo _windows
        fi
        mv "$MIL_tmp"/prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MILB_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}_AllInclusive.7z "$MILS_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}.* "$MILS_dir"
    fi

    if $CleanUp; then
        rm -fr "$MIL_tmp"
    fi

}

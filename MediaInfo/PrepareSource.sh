# MediaInfo/Release/PrepareSource.sh
# Prepare the source of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function _get_source () {

    local RepoURL

    if [ $(b.opt.get_opt --repo) ]; then
        RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        RepoURL="https://github.com/MediaArea/"
    fi

    cd $WPath
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of MediaInfo
    if [ $(b.opt.get_opt --source-path) ]; then
        MI_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo MediaInfo $RepoURL $WPath/repos
        MI_source=$WPath/repos/MediaInfo
    fi

    # Dependency : MediaInfoLib (will also bring ZenLib and zlib)
    cd $(b.get bang.working_dir)
    $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -r $RepoURL -w $WPath -${Target} -na -nc

    # Dependency : wxWidgets
    if [ $(b.opt.get_opt --wx-path) ]; then
        WX_source=$(sanitize_arg $(b.opt.get_opt --wx-path))
    else
        cd $WPath/repos
        git clone -b "v3.0.2" https://github.com/wxWidgets/wxWidgets
        WX_source=$WPath/repos/wxWidgets
    fi

}

function _linux_cli_compil () {

    echo
    echo "Generate the MI CLI directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir MediaInfo_CLI${Version}_GNU_FromSource
    cd MediaInfo_CLI${Version}_GNU_FromSource

    cp -r $MI_source .
    mv MediaInfo/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    mkdir -p Shared/Source
    cp -r $WPath/repos/zlib Shared/Source
    mkdir -p Shared/Project/zlib
    # TODO: put this directly in MI/Shared/Project/zlib/Compile.sh
    #echo "cd ../../Source/zlib/ ; make clean ; ./configure && make" > Shared/Project/zlib/Compile.sh
    echo "cd ../../Source/zlib/ ./configure && make" > Shared/Project/zlib/Compile.sh

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/GUI
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Contrib
        cd Source
            rm -fr Source/GUI
            rm -fr Source/Install
            rm -fr Source/PreRelease
            rm -fr Source/Resource
        cd ..
    cd ..

    echo "3: Autogen..."
    cd ZenLib/Project/GNU/Library
    sh autogen > /dev/null 2>&1
    cd ../../../../MediaInfoLib/Project/GNU/Library
    sh autogen > /dev/null 2>&1
    cd ../../../../MediaInfo/Project/GNU/CLI
    sh autogen > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tgz MediaInfo_CLI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tbz MediaInfo_CLI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.txz MediaInfo_CLI${Version}_GNU_FromSource)
    fi

}

function _linux_gui_compil () {

    echo
    echo "Generate the MI GUI directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir MediaInfo_GUI${Version}_GNU_FromSource
    cd MediaInfo_GUI${Version}_GNU_FromSource

    cp -r $MI_source .
    mv MediaInfo/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    mkdir -p Shared/Source
    cp -r $WPath/repos/zlib Shared/Source
    mkdir -p Shared/Project/zlib
    # TODO: put this directly in MI/Shared/Project/zlib/Compile.sh
    #echo "cd ../../Source/zlib/ ; make clean ; ./configure && make" > Shared/Project/zlib/Compile.sh
    echo "cd ../../Source/zlib/ ./configure && make" > Shared/Project/zlib/Compile.sh

    # Dependency : wxWidgets
    cp -r $WX_source Shared/Source/WxWidgets
    # TODO: modify configure.ac to do directly:
    # test -e .../Shared/Project/wxWidgets/Compile.sh
    touch Shared/Project/WxWidgets.sh
    mkdir Shared/Project/WxWidgets
    # TODO: put this directly in MI/Shared/Project/wxWidgets/Compile.sh
    #echo "cd ../../Source/WxWidgets ; make clean ; ./configure --disable-shared --disable-gui --enable-unicode --enable-monolithic \$* && make" > Shared/Project/WxWidgets/Compile.sh
    echo "cd ../../Source/WxWidgets ; ./configure --disable-shared --disable-gui --enable-unicode --enable-monolithic \$* && make" > Shared/Project/WxWidgets/Compile.sh

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_CLI.txt
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/CLI
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Contrib
        cd Source
            # Since the linux archive is also for mac
            #rm -fr GUI/Cocoa
            rm -fr GUI/VCL
            rm -fr GUI/VCL_New
            rm -fr Install
            rm -fr PreRelease
            rm -fr Resource/Plugin
            rm -f Resource/Language.csv
            rm -f Resource/Resources.qrc
        cd ..
    cd ..

    echo "3: Autogen..."
    cd ZenLib/Project/GNU/Library
    sh autogen > /dev/null 2>&1
    cd ../../../../MediaInfoLib/Project/GNU/Library
    sh autogen > /dev/null 2>&1
    cd ../../../../MediaInfo/Project/GNU/GUI
    sh autogen > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tgz MediaInfo_GUI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tbz MediaInfo_GUI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.txz MediaInfo_GUI${Version}_GNU_FromSource)
    fi

}

function _windows_compil () {

    echo
    echo "Generate the MI directory for compilation under Windows:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir mediainfo${Version}_AllInclusive
    cd mediainfo${Version}_AllInclusive

    cp -r $MI_source .

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_windows ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/libmediainfo_AllInclusive/MediaInfoLib .

    # Dependency : zlib
    cp -r $WPath/repos/zlib .

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -f .cvsignore .gitignore
        rm -fr .git
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -fr GNU Mac Solaris OBS
        cd ..
        rm -fr Source/GUI/Cocoa
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7z a -t7z -mx=9 -bd ../archives/mediainfo${Version}_AllInclusive.7z mediainfo${Version}_AllInclusive >/dev/null
    fi

}

function _linux_packages () {

    echo
    echo "Generate the MI directory for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    cp -r $MI_source .

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        #rm -fr Release
        cd Project
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr Mac Solaris OBS
        cd ..
        rm -fr Source/GUI/Cocoa
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/mediainfo${Version}.tgz MediaInfo)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/mediainfo${Version}.tbz MediaInfo)
        (XZ_OPT=-9 tar -cJ --owner=root --group=root -f ../archives/mediainfo${Version}.txz MediaInfo)
    fi

}

function btask.PrepareSource.run () {

    local MI_source WX_source

    cd $WPath

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr ZL
    rm -fr MIL
    rm -fr MI
    mkdir MI

    _get_source

    if [ "$Target" = "lc" ]; then
        _linux_cli_compil
        _linux_gui_compil
    fi
    if [ "$Target" = "wc" ]; then
        _windows_compil
    fi
    if [ "$Target" = "lp" ]; then
        _linux_packages
    fi
    if [ "$Target" = "all" ]; then
        _linux_cli_compil
        _linux_gui_compil
        _windows_compil
        _linux_packages
    fi
    
    if $CleanUp; then
        cd $WPath
        rm -fr repos
        rm -fr ZL
        rm -fr MIL
        rm -fr MI
    fi

}
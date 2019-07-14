#!/bin/sh

############ Server details ############

hostName="PEGASUS"
portNo="443"
protocol="https"

############ Server details ############

SUPPORT="assetexplorer-support@manageengine.com"
PRODUCT="AssetExplorer"

COMPUTERNAME=`hostname`
OUTPUTFILE="$COMPUTERNAME.xml"


main()
{
	echo "##### Scanning Started #####"
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><DocRoot>" >$OUTPUTFILE
	constructXML "ComputerName" "hostname"
	constructXML "OS_Category" "uname -s"
	echo "<Hardware_Info>" >>$OUTPUTFILE
	constructXML "OS_Category" "sw_vers"
	constructXML "Memory_Information" "sysctl hw.physmem"
	constructXML "Memory_Information" "sysctl hw.usermem"
	constructXML "Memory_Informationw" "sysctl hw.memsize"
	constructXML "Memory_Information" "sysctl vm.swapusage"
	constructXML "Computer_Information" "hostname"
	constructXML "Computer_Information" "hostname -s"
	constructXML "CPU_Information" "system_profiler SPHardwareDataType"
	constructXML "Disk_Space" "df -k"
	constructXML "NIC_Info" "/sbin/ifconfig"
	#-----------Last logged in user name -----------
	constructXML "Last_logged_user" "last | awk '{print \$1 \" \" \$3}'"
	#-------------Chipset, VRAM, Monitor display type, resolution---------------------
	constructXML "Monitoranddisplayinfo" "/usr/sbin/system_profiler SPDisplaysDataType"
	#--------------Sound card -----------------------------
	constructXML "SoundCardinfo" "/usr/sbin/system_profiler SPAudioDataType"
	#---------------Memory modules----------------------
	constructXML "MemoryInfo" "/usr/sbin/system_profiler SPMemoryDataType"
	#--------------Physical drives-------------------------
	constructXML "PhysicaldrivesInfo" "/usr/sbin/system_profiler SPParallelATADataType"
	#--------------Harddisk info if no data is available in SPParallelATADataType------------
	constructXML "HarddrivesInfo" "/usr/sbin/system_profiler SPSerialATADataType"
	#----------------Printer Info-----------------------
	constructXML "Printer_Info" "/usr/sbin/system_profiler SPPrintersDataType -xml"
	echo "</Hardware_Info>" >>$OUTPUTFILE
	echo "<Software_Info>" >>$OUTPUTFILE
	constructXML "Installed_Softwares" "system_profiler SPApplicationsDataType"
	echo "</Software_Info>" >>$OUTPUTFILE
	echo "</DocRoot>" >>$OUTPUTFILE
	echo "##### Scanning completed #####"
	#echo $data
	pushData
}

constructXML()
{
	##Need to replace the < into &lt; , > into &gt; and & into &amp;#####
	echo "<$1><command>$2</command><output><![CDATA[">>$OUTPUTFILE
	eval $2 >> $OUTPUTFILE 2>&1
	echo "]]></output></$1>" >>$OUTPUTFILE
}

pushData()
{
        data=$(cat $OUTPUTFILE)
        eval "type curl > /dev/null 2>&1"

        if [ $? -ne 0 ]
        then
                echo "curl is not installed, so could not post the scan data to $PRODUCT, You can import the  $COMPUTERNAME.xml available in the current directory into $PRODUCT using Stand Alone Workstations Audit. Executing the curl command will lead to the installation."
                exit 1
        fi

		curl -k --header "Content-Type: text/xml" --data-binary @$OUTPUTFILE "$protocol://$hostName:$portNo/discoveryServlet/WsDiscoveryServlet?COMPUTERNAME=$COMPUTERNAME"

		if [ $? -ne 0 ]
        then
		   rm -rf $OUTPUTFILE
           echo "$PRODUCT is not reachable. You can import the  $COMPUTERNAME.xml available in the current directory into $PRODUCT using Stand Alone Workstations Audit. For further queries, please contact $SUPPORT."
		   exit 1
        else
           rm -rf $OUTPUTFILE
           echo "Successfully scanned the system data, Find this machine details in $PRODUCT server."
        fi
}


main $*

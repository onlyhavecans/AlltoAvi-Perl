/***************************************************************************
 *   Copyright (C) 2006 by =-FOTD-=Sakuya aka. James Xu   
 *   genesis.kiith@gmail.com   
 *                                                                         
 *   This program is free software; you can redistribute it and/or modify 
 *   it under the terms of the GNU General Public License as published by  
 *   the Free Software Foundation; either version 2 of the License, or     
 *   (at your option) any later version.                                   
 *                                                                         
 *   This program is distributed in the hope that it will be useful,       
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          
 *                                                                         
 *   You should have received a copy of the GNU General Public License     
 *   along with this program; if not, write to the                         
 *   Free Software Foundation, Inc.,                                       
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             
 ***************************************************************************/
 
 /***************************************************************************
  * This is the GNU Linux Source, designed to compile on all
  * GNU C++ compilers under POSIX.
  * 
  * The Windows Source is in another foler, please go look
  * !! This code will not compile on Windows
  * 
  * Read Docs in the Doc folder for more information
  * ************************************************************************/
 
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <sys/stat.h>
#include <dirent.h>
#include <stdlib.h>

using namespace std;
 
 int main (int argc, char * argv[])
 {
 	//declare variables used:
 	unsigned int int_pos; //stores postition of the ":" char
 	string str_line; //a string value, for easier manipulation
 	string filename;
 	string ext;
	string str_input;
	string slash;
 	char * line;
	char * OS;
	
	unsigned int fFlag = 1; //Flag for FILE, 0 = true
	unsigned int osFlag = 0; //Flag for OS, 0 - POSIX, 1 - Win32
 	
 	//Variables used to read directory
 	DIR *dirHandle;
 	struct dirent *dirEntry;
 	
 	//used for help only
 	string sys_call = "mencoder INPUTNAME -sid SID -aid 0 -o OUTPUTNAME -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=BITRATE:vpass=1 -ffourcc CODEC -oac mp3lame -vf scale=W:H";	
 	
 	/************* Start of strings *******************/
 	string prefix = "mencoder ";
 	string sid = " -sid ";
 	string aid = " -aid ";
 	string out = " -o ";
 	string ovc = " -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=";
 	string vpass = ":vpass=1 -ffourcc ";
	string oac = " -oac mp3lame ";
 	string scale = "-vf scale=";
 	string scale_breaker = ":";
 	string cmd = "If you see this there is an error";
 	/************* End of strings *******************/
 	
 	struct stat;
 	
 	//Check for valid parameters:
	//Is param2 FILE?
	
	//debug
	cout << argc << " + " << argv[1] << endl << endl;
	
	if (strcmp(argv[1], "FILE") != 0)
	{
		fFlag = 1;
 		if (argc < 9)
 		{
 			cout << "Parameters missing, usage:" << endl;
 			cout << "alltoavi 1 2 3 4 5 6 7 8 9 10" << endl << endl;
 			cout << "Arguments taken:" << endl; 
 			cout << "\t 0. App path [Do not need to supply]" << endl;
 			cout << "\t 1. Directory of files OR \"FILE\" | TYPE string" << endl;
  			cout << "\t 2. Filetype, without the dot, is ignored if param 1 set to FILE | TYPE string" << endl;
  			cout << "\t 3. Subtitle Track ID, default one is 0, -1 for no sub, -2 is external sub | TYPE int" << endl;
  			cout << "\t 4. Audio Track ID, default is 0, -1 for no audio, -2 is external audio | TYPE int" << endl;
  			cout << "\t 5. Video bitrate in KBPS | TYPE int" << endl;
  			cout << "\t 6. Codec Name, ie DIVX50/XVID | TYPE string" << endl;
  			cout << "\t 7. Output video Width | TYPE int" << endl;
  			cout << "\t 8. Output video Height | TYPE int" << endl;
			cout << "\t 9. Output Dir | TYPE string" << endl;
			cout << "\t10. If FILE is specified in param 1, then this is needed to give the filename | TYPE string" << endl << endl;
			cout << "Usage example [2.0.6]: alltoavi \"C:\\movies\" mkv 0 0 650 DIVX50 320 240" << endl;
  			cout << "the above will convert all mkvs in C:\\movies into 650KBPS DivX 5.0 avis with screen size of 320x240, subtitle 1 and audio 1" << endl << endl;
  			cout << "Usage example [2.1.0]: alltoavi FILE mkv 0 0 650 DIVX50 320 240 \"C:\\output\" \"C:\\file1.mkv\"" << endl;
			cout << "the above will convert with the same setting as the above example for 2.0.6, but it will only convert 1 file and the output is saved into C:\\output" << endl << endl;

  			return 1;
		}
	}
	else
	{
		fFlag = 0;
		if (argc < 10)
 		{
 			cout << "Parameters missing, usage:" << endl;
 			cout << "alltoavi 1 2 3 4 5 6 7 8 9 10" << endl << endl;
 			cout << "Arguments taken:" << endl; 
 			cout << "\t 0. App path [Do not need to supply]" << endl;
 			cout << "\t 1. Directory of files OR \"FILE\" | TYPE string" << endl;
  			cout << "\t 2. Filetype, without the dot, is ignored if param 1 set to FILE | TYPE string" << endl;
  			cout << "\t 3. Subtitle Track ID, default one is 0, -1 for no sub, -2 is external sub | TYPE int" << endl;
  			cout << "\t 4. Audio Track ID, default is 0, -1 for no audio, -2 is external audio | TYPE int" << endl;
  			cout << "\t 5. Video bitrate in KBPS | TYPE int" << endl;
  			cout << "\t 6. Codec Name, ie DIVX50/XVID | TYPE string" << endl;
  			cout << "\t 7. Output video Width | TYPE int" << endl;
  			cout << "\t 8. Output video Height | TYPE int" << endl;
			cout << "\t 9. Output Dir | TYPE string" << endl;
			cout << "\t10. If FILE is specified in param 1, then this is needed to give the filename | TYPE string" << endl << endl;
			cout << "Usage example [2.0.6]: alltoavi \"C:\\movies\" mkv 0 0 650 DIVX50 320 240" << endl;
  			cout << "the above will convert all mkvs in C:\\movies into 650KBPS DivX 5.0 avis with screen size of 320x240, subtitle 1 and audio 1" << endl << endl;
  			cout << "Usage example [2.1.0]: alltoavi FILE mkv 0 0 650 DIVX50 320 240 \"C:\\output\" \"C:\\file1.mkv\"" << endl;
			cout << "the above will convert with the same setting as the above example for 2.0.6, but it will only convert 1 file and the output is saved into C:\\output" << endl << endl;

  			return 1;
		}
 	}
 	
 	//check OS:
	OS = getenv("MANPATH");
	if (OS == NULL)
	{
		cout << "OS Version: Win32" << endl;
		osFlag = 1;
	}
	else
	{
		cout << "OS Version: POSIX" << endl;
		osFlag = 0;
	}

	/***********************************************************************************
	 *  Parse required to break the line:
	 *  -rwxr-xr-x  1 sakuya_su root 107790 2006-01-05 12:06 converter
	 *  to:
	 *  06 converter 
	 ***********************************************************************************/
	//debug
	//cout << "system() = " << sys_call << endl << endl; 
	cout << "fFlag = " << fFlag << endl;
	cout << "osFlag = " << osFlag << endl;
	 
	//Print out front page
	cout << "************************************************" << endl;
	cout << "* Unix name: alltoavi" << endl;
	cout << "* Hosted on: Sourceforge" << endl;
	cout << "* " << endl;
	cout << "* Coded by: Sakuya, aka James Xu" << endl;
	cout << "* Email: genesis.kiith@gmail.com" << endl;
	cout << "*" << endl;
	cout << "* Comments: Ah, to help out all the" << endl;
	cout << "* Anime lovers who hate mkv/ogm XD" <<endl;
	cout << "************************************************" << endl << endl << endl;
	cout << "Stdout:" << endl;
	
	//--2.1.0--
	if (fFlag == 0)
	{
		//debug
		cout << "FILE Mode" << endl;
		
		str_line = argv[10];
		if (osFlag == 0)
			slash = "/";
		else
			slash = "\\";
		int_pos = str_line.rfind (slash, str_line.length() );
		str_line = str_line.substr (int_pos + 1);
		
		//debug
		cout << "str_line: " << str_line << endl;
		
		goto FILEMODE;
	}
		
	
	//change dir
	dirHandle = opendir (argv[1]);
	//dirHandle = opendir ("/home/sakuya_su/bin/try/mst2");
	//If dir is invalid:
	if (!dirHandle)
	{
		cout << "!!!!! Error: Invalid directory" << endl;
		
		exit (1);
	}
	//dir is valid:
	while ( (dirEntry = readdir(dirHandle)) != 0 ) 
	{
		str_line = dirEntry->d_name;

FILEMODE: //<-------FILEMODE Only
        	int_pos = str_line.rfind (".", str_line.length() );

        	//check if the name is a hidden POSIX folder
        	if (int_pos < 2 || int_pos > 250)
        	{
        		continue;
        	}
        
        	//debug:
        	//cout << "String is: " << str_line << endl;
        	//cout << "Int count: " << int_pos << endl;
        
  		filename = str_line.substr(0, int_pos);
  		ext = str_line.substr(int_pos + 1);
  		
  		//dismiss if not the right ext:
  		if (ext != argv[2])
  		{
  			continue;
  		}
       		
		if (fFlag == 0)
		{
			str_input = argv[10];
		}
		else
		{
			str_input = argv[1];
			if (osFlag == 0)
				str_input +=  "/";
			else
				str_input += "\\";
			str_input += filename + "." + ext;
		}

  		//debug:
  		//cout << filename << " " << ext << endl;
		cout << "str_input: " << str_input << endl;

  		//system:
  		cout << "generating system(); call, please check below to debug" << endl;
  		
  		//Generate the call string, table as follows:
  		/************* Start of strings *******************
 		string prefix = "mencoder ";
 		string sid = " -sid ";
 		string aid = " -aid ";
 		string out = " -o ";
 		string ovc = " -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=";
 		string vpass = ":vpass=1 -ffourcc ";
		string oac = " -oac mp3lame ";
 		string scale = " -vf scale=";
 		string scale_breaker = ":";
 		string cmd = "If you see this there is an error";
 		************** End of strings *******************/
 		//cout << argv[3] << endl;
		if ( strcmp(argv[3],  "-1") == 0 ) //no Sub
 		{
 			//system:
 			cout << " * No SID " <<endl;
 			sid = "";
 		}
 		else
 		{
 			sid += argv[3];
 		}
 		
		if ( strcmp(argv[3], "-2") == 0 )
		{
			sid = " -sub " + filename + ".srt";
			//system
			cout << " * External Subtitle: " << sid << endl;
		}

 		if ( strcmp(argv[4],  "-1") == 0 )//no audio
 		{
 			//system:
 			cout << " * No AID " << endl;
 			
 			aid = " -noaudio";
 		}
 		else
 		{
 			aid += argv[4];
 		}
 		
		if ( strcmp(argv[4], "-2") == 0 )
		{
			aid = " -audiofile " + filename + ".mp3";
			oac = "";
			//system
			cout << " * External Audio: " << aid << endl;
			cout << " OAC Change: |" << oac << "|" << endl;
		}
 		ovc += argv[5]; //Bitrate
 		vpass += argv[6]; //Codec
 		scale += argv[7] + scale_breaker + argv[8]; //Resize	
		
		cmd = prefix + "\"" + str_input;
		cmd += "\"" + sid + aid + out + "\"" + argv[9];
		if (osFlag == 0)
			cmd += "/";
		else
			cmd += "\\";
		cmd += "cvt_" + filename + ".avi\"" + ovc + vpass + oac + scale;
		
		cout << cmd << endl;
		
		/*OLD BLOCK
		//!!!!!! change on windows      *** 
		cmd = prefix + "\"" + argv[1] + "/" +  filename + "." + ext + "\"" + sid + aid;
		cmd += out + "\"" + argv[1] + "/" + "cvt_" + filename + ".avi\"";
		cmd += ovc + vpass + oac + scale;
		*/

		//system:
		cout << "-----Check-----Check-----Check-----Check-----" << endl << cmd << endl << endl;
		
 		/****************************************************************************
  		* Arguments taken:
  		* 0. App path
 		 * 1. DIR
  		* 2. FILETYPE
  		* 3. SID
  		* 4. AID
  		* 5. BITRATE
  		* 6. CODEC
  		* 7. H
  		* 8. W
  		****************************************************************************/
  		
  		line = &cmd[0];
		
		//debug:
		printf ("%s\n\n\n", line);
		
		break;
		system (line); 	
		
		/***********************Return variables******************************/
		prefix = "mencoder ";
 		sid = " -sid ";
 		aid = " -aid ";
 		out = " -o ";
 		ovc = " -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=";
 		vpass = ":vpass=1 -ffourcc ";
		oac = " -oac mp3lame ";
 		scale = "-vf scale=";
 		scale_breaker = ":";
 		cmd = "If you see this there is an error";
 		/***********************Return variables******************************/

		if (fFlag == 1)
		{
			break;
		}
		
	 }
		
	 return 0;
	 
 }
 
 
 /*************************************
  * James Xu 2006
  * aka.
  * Sakuya
  * **********************************/

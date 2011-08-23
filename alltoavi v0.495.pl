#!/usr/bin/perl -w
use strict;
use File::Spec;

=head1 BatchAvi - Current version v0.4.9.5 (recoded alpha)

This takes a outdir and a list of files and bach converts them to xvid avi
baised on settings prompted to the user.
The main design of this software is to create high quality files for set top
divx players and handheld devices like my lovely gp2x

To do
Find more optimised settings for files
Fix the desync issue for video greater than a hour
Create profiles (fullscreen setup, widescreen setop, gp2x, straight convert)
=cut

#Help and usage in a var makes it harder to read in program but easier to maintame and spit out at will.
my $help = "BatchAvi - Usage: BatchAvi outdir (files) \nBatchAvi requires at least two command line options, the output directory and a list of all the files you wish to convert.\nie BatchAvi /tmp/out file1 file2 file3\nThis version will prompt for the rest of the info\n";
my ($outputdir, @filelist, @profile);

#Because My functions are so extensive I put them below main

MAIN: {
	 #Lets first test to see that we have all our argvs
	die $help unless ( @ARGV >= 2 );
	#This function will die the program if the argvs are no good
	($outputdir, @filelist) = parse_args(@ARGV);
	
	##runs midentify on what it is fed and spits out into in perdy format to the user
	if (get_line("Do you want to check the files stats[y/n]? ") =~ /y(es)?/i ) {
		identify_files(@filelist)
	}
	
	@profile = set_profile();
	print "\n\n";
	
	#This sets up logging, I'd put it in it's own function but...
	open LOG, ">encoding.log"
		or die "Unable to create log file ($1)\n";
	select LOG;
	$| = 1;
	select STDOUT;

	my @failedfiles;
	foreach my $file (@filelist) {
		unless (encode_file($file, $outputdir)) {
			push @failedfiles, $file;
		}
		print "\n";
	}
	
	close LOG;
	
	print "All done!!!\n";
	if (@failedfiles) {
		print "The following files spit back a error from mencoder though, you might want to double check them;\n";
		print join("\n", @failedfiles)."\n";
	}
}

#Here is my functions

sub get_line { #My favoriate input getter
	print $_[0];
	chomp(my $line = <STDIN>);
	return $line;
};

sub parse_args { #takes the arguments and returns the outdir and then the files in array context, also moves to the outdir
	my $outdir = File::Spec->rel2abs( shift(@_) );
	die "Output directory $outdir does not exist\n$help" unless -d $outdir;
	my @flist;
	foreach my $file (@_) {
		if (-f $file) { push @flist, $file }
	}
	die "You did not specify any valid files!!!\n" unless (@flist);
	
	return ($outdir, @flist);
};

sub identify_files { #Takes a array of files and returns void, lists file stats to user
	print "Please wait while we parse all the video information this may take a little bit if there is alot of files\n";
	foreach my $file (@_) {
		my (@subidvid, @audidvid, $widthvid, $heightvid, $bitratevid);
		open IDENTIFY, "-|", "mplayer", "-vo", "null", "-ao", "null", "-frames", "0", "-identify", $file or die "Cannot launch mplayer! Please check your paths and mplayer installation ($!)";
			while (<IDENTIFY>) {
				/ID_SUBTITLE_ID=(\d+)/		&& do {push @subidvid, $1;	next};
				/ID_AUDIO_ID=(\d+)/			&& do {push @audidvid, $1;	next};
				/ID_VIDEO_WIDTH=(\d+)/		&& do {$widthvid = $1;		next};
				/ID_VIDEO_HEIGHT=(\d+)/		&& do {$heightvid = $1;		next};
				/ID_VIDEO_BITRATE=(\d+)/	&& do {$bitratevid = $1;	next};
			};
		close IDENTIFY;
		#whew now comes the outputting
		printf "The file %s has the following configuration;\n", $file;
		printf "It is currently %dx%d and has the reported bit rate of %dkbs\n", $widthvid, $heightvid, $bitratevid / 1024 ;
		printf "It has the audio track ids of %s\n", join(", ", @audidvid) if (@audidvid);
		printf "If present the subtitles tracks are ids %s\n", join(", ", @subidvid) if (@subidvid);
		print "\n";
	}
	print "\n"
};

sub set_profile { #takes void and returns the profile # with a array of the settings needed by ret_settings if it is 0 (custom)
	my %settings = (
		"sid"		=>	"1) Enter the id for the subtitle desired, -2 for external sub file or -1 for none",
		"aid"		=>	"2) Enter the id for the audio track desired, -2 for external mp3 or -1 for default",
		"quaint"	=>	"3) Enter the desired bitrate",
		"scale"		=>	"4) Enter the desired video dimentions in the format widthxheight, ie 640x480 or 0 to leave unchanged",
		"expand"	=>	"5) Enter the desired border dimentions in the format widthxheight, ie640x480 or 0 for none\nWhen using a border the video must be smaller than this setting",
	);
	
	my ($profilenum, @custsettings);
	print "Please choose a profile for encoding your files by number\n";
	print "Add a - to the front of the number to only encode the first minute (test mode);\n";
	print "0) Custom, enter your own settings\n";
	print "1) Straight convert to xvid, no changes to video\n";
	print "2) Convert for setop xvid player, fullscreen source video\n";
	print "3) Convert for setop xvid player, widescreen source video\n";
	print "4) Convert for gp2x, any source video\n";
	do {
		$profilenum = get_line("Please enter your choice: ");
		print "That is not a valid responce, try again\n" unless ($profilenum =~ /-?[0-4]/);
	} until ($profilenum =~ /-?[0-4]/);
	
	if ($profilenum == /-?0/) {
		foreach (sort {$settings{$a} cmp $settings{$b}} keys %settings) {
			$settings{$_} = get_line($settings{$_}.": "); #this is a great code saver
		}
		#user input must be tested
		($settings{sid}		=~ /^-?\d+$/ )			or die "$settings{sid} is not a valid setting for the subtitle id.\n";
		($settings{aid}		=~ /^-?\d+$/ )			or die "$settings{aid} is not a valid setting for the audio id.\n";
		($settings{quaint}	=~ /^\d+$/ )			or die "$settings{quaint} is not a valid number!\n";
		($settings{scale}	=~ /^(\d+x\d+|0)$/ )	or die "$settings{scale} is not a valid dimention, please choose a valid dimention in the format of widthxhight.\n";
		($settings{expand}	=~ /^(\d+x\d+|0)$/ )	or die "$settings{expand} is not a valid dimention, please choose a valid dimention in the format of widthxhight.\n";
		if (($settings{scale} != 0) && ($settings{expand} != 0)) {
			($settings{wscale}, $settings{hscale}) = split(/x/, $settings{scale});
			($settings{wexpand}, $settings{hexpand}) = split(/x/, $settings{expand});
			($settings{wscale} < $settings{wexpand}) or die "The border must extend past the visible video";
			($settings{hscale} < $settings{hexpand}) or die "The border must extend past the visible video";
		 @custsettings = ($settings{sid}, $settings{aid}, $settings{quaint}, $settings{wscale}, $settings{hscale}, $settings{wexpand}, $settings{hexpand});
		};
	};
	return ($profilenum, @custsettings);
};

sub ret_settings { #takes the profile # and returns the array of the settings (testmode, sid, aid, quaint, wscale, hscale, wexpand, hexpand)
	my ($preset, @custom) = @_;
	my $testmode = 0;
	if ($preset =~ /-(\d+)/) {
		$testmode = 1;
		$preset = $1;
	}
	
	if ($preset == 0) {
		return ($testmode, @custom)
	} elsif ($preset == 1) { return ($testmode, -1, -1, 900, 0, 0, 0, 0)
	} elsif ($preset == 2) { return ($testmode, -1, -1, 900, 660, 440, 720, 480)
	} elsif ($preset == 3) { return ($testmode, -1, -1, 900, 660, 330, 720, 480)
	} elsif ($preset == 4) { return ($testmode, -1, -1, 400, 320, -3, 0, 0)
	} else {
		die "FUCK!!!!!
			This was tottally supposto return (testmode, sid, aid, quaint, wscale, hscale, wexpand, hexpand)
			But it seems something is really jacked up\n";
	}
};

sub command { #takes array containing filename, outdir and pass #, and the settings array then returns the mencoder command in array format
	my ($file, $outdir, $vpass, $test, $sid, $aid, $quaint, $wscale, $hscale, $wexpand, $hexpand) = (@_);
	
	$file =~ m/^(.*)\.(\w{3,4})$/; my $name = $1; 	#Cause the prefix is just a little importaint
	my ($outfile, $quality, @sid, @aid, @oac, @endpos, @filters);
	
	# The outname, null device for the first pass
	if ($vpass == 1) {
		$outfile = File::Spec->devnull();
	} else {
		my ($foo, $bar, $newname) = File::Spec->splitpath($name);
		$outfile = File::Spec->catfile($outdir, "cvt_".$newname.".avi");
	}

	# The AID and OAC

	if ($aid == -2 ) {
		@aid = ("-audiofile", "$name.mp3");
	} elsif ($aid == -1) {
		@oac = ("-oac", "mp3lame");
	} else {
		@aid = ("-aid", $aid);
		@oac = ("-oac", "mp3lame");
	}	
	
	# The SID
	if ($sid == -2 ) {
		my $sub;
		print "Looking for $name.sub\n";
		for (;;) {
			-f "$name.ssa" && do {$sub = ".ssa";	last};
			-f "$name.srt" && do {$sub = ".srt";	last};
			-f "$name.sub" && do {$sub = ".sub";	last};
			die "A known external sub file does not exist for $file!!\n";
		}
		@sid = ("-sub", "$name.$sub");
	} elsif ($sid == -1 ) {
		@sid = ();
	} else {
		@sid = ("-sid", $sid);
	}
	
	# The size and optional expand
	if (($wscale != 0) && ($hscale != 0)) {
		@filters = ("-vf", sprintf "scale=%d:%d", $wscale, $hscale);
		if (($wexpand != 0) && ($hexpand != 0)) {
			$filters[0] = "-vf";
			$filters[1] .= sprintf(",expand=%d:%d", $wexpand, $hexpand);
		}
	}

	#the optitinal endpos
	@endpos = ("-endpos", "60") if ($test == 1);
	
	#these are the encoding settings. It should be scalar.
	#me_quality=4:vhq=4:bvhq=1:turbo:autoaspect:nopacked:chroma_opt:quant_type=mpeg:
	$quality = "me_quality=4:vhq=4:bvhq=1:turbo:autoaspect:nopacked:quant_type=mpeg:profile=dxnhtntsc"
		if ($vpass == 1);
	$quality = "me_quality=4:vhq=4:bvhq=1:turbo:autoaspect:nopacked:chroma_opt:quant_type=mpeg:profile=dxnhtntsc"
		if ($vpass == 2);

	#spit out the goods
	return ("mencoder", "-quiet", $file, @aid, @sid, "-o", $outfile, "-oac", "mp3lame", "-ovc", "xvid", "-xvidencopts", "bitrate=${quaint}:$quality:pass=${vpass}", "-ffourcc", "XVID", @endpos, @filters);
}

sub encode_file { #takes a filename and outdir in array format, returns nonzero for failure during convert
	my ($file1, $outdir) = (@_);
	my $fail = 0;
	for (my $pass = 1; $pass <= 2; $pass++) {
		print "$file1; pass #$pass, this may take a while!\n\n";
		print LOG "Starting $file1; pass #$pass ".`date`."\n";
		print command($file1, $outdir, $pass, ret_settings(@profile));
		open MENCODE, "-|", command($file1, $outdir, $pass, ret_settings(@profile))
			or $fail = 1;
		while (<MENCODE>) { print LOG $_ };
		print LOG "Completed $file1; pass #$pass ".`date`."\n";
	};
	print LOG "File $file1 Completed ".`date`."\n\n";
	unlink "divx2pass.log";
	return $fail;
};

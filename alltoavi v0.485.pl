#!/usr/bin/perl -w
use strict;
use File::Spec;

=head1 All to Avi Perl - Current version v0.4.8.5 (Tested Beta)

This is what I put out for each file in the listed directory with the appropiate
filetype; mencoder INFILE [-aid #] [-sid # or -sub INFILE.xxx] -o
OUTFILE -oac mp3lame -ovc lavc -lavcopts vcodec=mpeg4:[encopts]:vbitrate=###:vpass=# -ffourcc
DX50 [-vf scale=###:###][,expand=###,###] [-endpos 30]

Currently only SSA, SUB, and SRT subs are supported and the extentions must be
lowercase. I do plan to add more and more and more subtitle options as I find
out what exactly is compatible with mencoder and has no issues

Currently only mp3 external audio is supported.. I have no idea if I will will
add support for other types or if mencoder will even take them without issue. It
is not that that hard of a feature to implement but I have no idea what types.

The settings for adding borders and setting it to TV size in mencoder are
scale=660:440,expand=720:480 for normal anime and doing the scale 660:330 for
that awesome Naruto movie ^.^

You might notice I NEVER manipulate the directories except for setting the
output dir & file. This is why File::Spec is used, it allows you to set
directories and paths OS independently. File::Spec is almost always a default
module so there shouldn't be any compatiblity isses.

40 * 25 * width * height / 256 / 1000 = $suggested_optimal_bitrate??

Getting the lavcopts is really big right now, the mixing of quality and time is
importiant. I don't want more that twice the time but I am a big stickler for
quality and the main concept behind this software is lossy to lossy conversion.
Right now I am just reviewing different choices and what will give me the best
quality. The original alltoavi seemed to use nothing but the defaults.. and in
my testing this produced very sub optimal video. Again, alot more testing is
needed and alot of input! Here is the options I am currently looking at testing
vcodec=mpeg4:vbitrate=###:pass=#:mbd=2:trell:v4mv:last_pred=(2|3):dia=(2|4):vmax_b_frames=2:vb_strategy=1:cmp=(2|3):subcmp=(2|3):precmp=(2|0)(:turbo)


I am very tempted to just make this only encode using the xvid encoder in
mencoder. The plus is that I can take out some prompts (like the codec one for
starters), At that point I can probbaly enter quality/type levels for movies,
anime and portable. but those prolly won't show up till a pre1.0 release. My
only concern with that though is the slighty more difficult to configure xvid
encoder and also loosing another sliver of compatiblitly because then I also
have more requirements to run. Usually though if you have mencoder you have
xvid... expecially seeing the xvidops ability and what not. Here is the settings
and strings I need to test for xvid pass=#:bitrate=###:me_quality=(4|5):vhq=4:bvhq=1:nopacked:chroma_opt:quant_type=mpeg:autoaspect
and for standaloneplayer mode add profile=dxnhtntsc to it and demand -fourcc
DX50 In fact I think I should actually just change the scope of this version of
all to avi to force xvid and just pick preset qualities and presets.. this may
really be a time and pain saver while isolating another nitch of file tweakers.



To do for next beta, `+`=completed `-`=partially completed `\`=cut from current
+1) Get the test option working
+2) expand and scale settings all straigtened out and working
+2.5) presets for resizing full screen and widescreen files for standard tv
\) suggested bitrate (midentify's ability to cope prevents this insofar)
+4) allow for not resizing the video at all
+5) Fix &identify_files
+5.1) Find cause for bug and "fix" work around for &identify_files eating @find
\) Enhance &identify_files to return data for presets or suggested settings
+6) Get 2 pass mode working !!! big feature!!!
+7) Figure out the caviats of the system function and simplfy the call
-8) Find more optimised settings for files
+9) Fix pathing to be a little more careful with input using File::Spec
10) Allow for leaving off the outputdir to encode right back to input
11) Test and configure using the actual xvid encoder though mencoder(-xvidopts?)
12) allow for not specifying the aid and sid to just ??accept them all??

=cut

#Help and usage in a var makes it harder to read in program but easier to maintame and spit out at will.
my $help = "All to AVI Perl - Usage: alltoavi.pl filetype inputdir [outputdir] \nalltoavi perl requires three command line options, the extention for the file type to convert, the input directory, and the output directory.\nie alltoavi mkv /tmp/toavi /tmp/out\nThis version will prompt for the rest of the info\n";

#All the into for the actual files
my ($filetype, $inputdir, $outputdir, @filelist, @failedfiles);
#We are going to use a hash to collect all user input and then put the actual setting into vars after checks for safetey
my %settings = (
	"sid"		=>	"1) Enter the id for the subtitle desired, -2 for external sub file or -1 for none",
	"aid"		=>	"2) Enter the id for the audio track desired, -2 for external mp3 or -1 for default",
	"bitrate"	=>	"3) Enter the desired bitrate, greater than 300 is desired",
	"size"		=>	"4) Enter the desired dimentions in the format widthxheight, ie 640x480 or 0 to leave unchanged",
	"test"		=>	"5) If you want to enable test mode (only encode first 30 seconds) enter yes",
	"tvsafe"	=>	"6) If you want to use a stand-alone player w/ TVsafe preset(overrides size settings) enter yes",
);

sub get_line { #My favoriate input getter
	print $_[0];
	chomp(my $line = <STDIN>);
	return $line;
}

sub parse_args_files {
	if ( @ARGV == 3) {
		$filetype = $ARGV[0];
		$inputdir = File::Spec->rel2abs( $ARGV[1] );
		die "intput directory $inputdir does not exist\n$help" unless -d $inputdir;
		$outputdir = File::Spec->rel2abs( $ARGV[2] );
		die "Output directory $outputdir does not exist\n$help" unless -d $outputdir;
		chdir $inputdir or die "Cannot move to the input directory $inputdir, do you have permissions? ($!)\n";
		@filelist = (glob "*.\L$filetype\E *.\U$filetype\E");  
		die "There are no file with the extention $filetype in $inputdir!\n" unless (@filelist);	
	} elsif ( @ARGV == 2 and -f $ARGV[0] ) {
		my $volume, my $path, my $builtpath;
		($volume,$path,@filelist) = File::Spec->splitpath( $ARGV[0] ); # my this needs work
		$builtpath = File::Spec->catdir( $volume, $path );
		$inputdir = File::Spec->rel2abs( $builtpath );
		$outputdir = $inputdir;
		die "Output directory $outputdir does not exist\n$help" unless -d $outputdir;
		chdir $inputdir or die "Cannot move to the input directory $inputdir, do you have permissions? ($!)\n";
	} else { die $help; }
	
};

sub identify_files { #Eventually this will return valuable info but not it just spits it all out to the user
	print "Please wait while we parse all the video information this may take a little bit if there is alot of files\n";
	foreach my $file (@filelist) {
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

sub get_settings {
	foreach (sort {$settings{$a} cmp $settings{$b}} keys %settings) {
		$settings{$_} = get_line($settings{$_}.": "); #this is a great code saver
	}
	#this is where it gets ugly... This could go in the loop but why run frivilous checks over and over.
	($settings{sid}		=~ /^-?\d+$/ )			or die "$settings{sid} is not a valid setting for the subtitle id.\n";
	($settings{aid}		=~ /^-?\d+$/ )			or die "$settings{aid} is not a valid setting for the audio id.\n";
	($settings{bitrate}	=~ /^\d+$/ )			or die "$settings{bitrate} is not a valid number!\n";
	($settings{size}	=~ /^(\d+x\d+|0)$/ )	or die "$settings{size} is not a valid dimention, please choose a valid dimention in the format of widthxhight.\n";
	($settings{test}	=~ /(yes|no)/i )		or die "Please answer if you want to run test mode yes or no\n";
	($settings{tvsafe}	=~ /(yes|no)/i )		or die "Please answer if you want to encode for setop use yes or no\n";
	if ($settings{tvsafe} =~ /yes/i ) {
		$settings{tvsafe} = get_line("9) Is the original file widescreen or fullscreen: ");
		($settings{tvsafe} =~ /^(wide|full)/i )	or die "You need to enter either widescreen or fullscreen.\n"
	}
	#$settings{border&&test} are checked in the next function, they are y/n prompts anyways
};

sub command { #this expects to be fed the full filename and the pass # in array formay
	my ($file, $vpass) = (@_);					#The filename and vpass
	$file =~ m/^(.*)\.(\w{3,4})$/; my $name = $1; 	#Cause the prefix is just a little importaint
	my (@aid, @sid, $outfile, $quality, $bitrate, $codec, @oac, @endpos, @filters);
	
	# The outname, null device for the first pass
	if ($vpass == 1) {
		$outfile = File::Spec->devnull();
	} else {
		$outfile = File::Spec->catfile($outputdir, "cvt_$name.avi"); #Very carefully set the outfile, and use File::Spec for compatiblity
	}

	# The AID and OAC

	if ($settings{aid} == -2 ) {
		@aid = ("-audiofile", "$name.mp3");
	} elsif ($settings{aid} == -1) {
		@oac = ("-oac", "mp3lame");
	} else {
		@aid = ("-aid", $settings{aid});
		@oac = ("-oac", "mp3lame");
	}	
	
	# The SID
	if ($settings{sid} == -2 ) {
		my $sub;
		print "Looking for $name.sub\n";
		for (;;) {
			-f "$name.ssa" && do {$sub = ".ssa";	last};
			-f "$name.srt" && do {$sub = ".srt";	last};
			-f "$name.sub" && do {$sub = ".sub";	last};
			die "A known external sub file does not exist for $file!!\n";
		}
		@sid = ("-sub", "$name.$sub");
	} elsif ($settings{sid} == -1 ) {
		@sid = ();
	} else {
		@sid = ("-sid", $settings{sid});
	}
	
	# Bitrate
	$bitrate = $settings{bitrate};
	
	# The size and optional expand
	my @size = split(/x/, $settings{size});
	my @expand;
	if ($settings{tvsafe} =~ /^full/i) {
		@filters = ("-vf", sprintf "scale=%d:%d,expand=%d:%d", 660, 440, 720, 480);
	} elsif ($settings{tvsafe} =~ /^wide/i) {
		@filters = ("-vf", sprintf "scale=%d:%d,expand=%d:%d", 660, 330, 720, 480);
	} else {
		unless ($size[0] == 0) {
			@filters = ("-vf", sprintf "scale=%d:%d", @size);
		}
	}
	
	#the optitinal endpos
	@endpos = ("-endpos", "60") if ($settings{test} =~ /yes/i);
	
	#these are the encoding settings. It should be scalar.
	$quality = "me_quality=4:vhq=4:bvhq=1:nopacked:quant_type=mpeg:autoaspect:turbo:profile=dxnhtntsc"
		if ($vpass == 1);
	$quality = "me_quality=4:vhq=4:bvhq=1:nopacked:chroma_opt:quant_type=mpeg:autoaspect:turbo:profile=dxnhtntsc"
		if ($vpass == 2);

	#spit out the goods
	return ("mencoder", $file, @aid, @sid, "-o", $outfile, "-oac", "mp3lame", "-ovc", "xvid", "-xvidopts", "$quality:bitrate=${bitrate}:vpass=${vpass}", "-ffourcc", "XVID", @endpos, @filters);
}

sub generate_stats { #this should be able to gen interesting stats about the encodes
	print "This function tottally does not do anything atm\n";
	print "But eventually it will parse the log and spit back interesting fun facts like average fps\n";
}

MAIN: {
	&parse_args_files;#Sets $filetype, $inputdir, $outputdir using the argvs, chdirs to $inputdir and then gets @filelist.
	&identify_files if (get_line("Do you want to check the files stats[y/n]? ") =~ /y(es)?/i ); #runs midentify on all files and spits out into in perdy format
	&get_settings; #Prompts for and sanity checks new values for all the keys in %settings using the current values as prompts
	print "\n\n";
	
	#This sets up logging, I'd put it in it's own function but...
	open LOG, ">encoding.log"
		or die "Unable to create log file ($1)\n";
	select LOG;
	$| = 1;
	select STDOUT;
	
	foreach my $file1 (@filelist) {
		for (my $pass = 1; $pass <= 2; $pass++) {
			print "$file1; pass #$pass, this may take a while!\n\n";
			print LOG "Starting $file1; pass #$pass\n";
			open MENCODE, "-|", &command($file1, $pass) #spits out the entire command in list format and at the system
				or push @failedfiles, $file1;
			while (<MENCODE>) { print LOG $_ };
			print LOG "Completed $file1; pass #$pass\n"
		};
		print LOG "File $file1 Completed\n\n";
		unlink "divx2pass.log";
		print "\n";
	}
	
	close LOG;
	
	&generate_stats;

	print "All done!!!\n";
	if (@failedfiles) {
		print "The following files spit back a error from mencoder though, you might want to double check them;\n";
		print join("\n", @failedfiles)."\n";
	}
}

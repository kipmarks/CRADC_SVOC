#! /usr/bin/perl
#
# CRADC
####$dir="/media/kip/Usb16Gb/CRADC_SVOC/original/20190617/";
####$dir="/media/kip/Usb16Gb/CRADC_SVOC/sasprogs/";
####@saslibs=("dss","tdw","dw","edw_curr","edw_raw","tdw_curr","tdw_raw","did_tmp","cradcwrk");
#
#Exclusions
$dir="/media/kip/Usb16Gb/CRADC_SVOC/original/20190617/exclusions/";
@saslibs=("cradc","dss","tdw","dw","edw_curr","edw_raw","tdw_curr","tdw_raw","did_tmp","csdr","exclwork","excltemp","ocamexcl","camexcl","b10debt");

opendir(DH,"$dir");
my @files = readdir(DH);
closedir(DH);

foreach my $file (@files)
{
	next if ($file =~ /^\.$/);
	next if ($file =~ /^\.\.$/);
	next if ($file !~ /\.sas$/i);
	open(my $fh, $dir.$file) || die "Could not open $file \n";

	while(my $row = <$fh>){
		$row =~ tr/A-Z/a-z/;
		foreach my $lb (@saslibs)
		{
			if ($row =~ /\b($lb\.\w{1,30}\b)/){
				print "$1 $2\n";
			}
		}
	}
	close($fh);
}

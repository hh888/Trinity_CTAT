#!/usr/bin/env perl

use strict;
use warnings;
use Pipeliner;

my $usage = "\n\n\tusage: $0 left.fq.gz right.fq.gz ctat_genome_lib.tar.gz [FusionInspector|DISCASM]\n\n";

my $left_fq_gz = $ARGV[0] or die $usage;
my $right_fq_gz = $ARGV[1] or die $usage;
my $ctat_genome_lib_tar_gz = $ARGV[2] or die $usage;

shift @ARGV;
shift @ARGV;
shift @ARGV;

my $STAR_FUSION_HOME = $ENV{STAR_FUSION_HOME} or die "Error, env var STAR_FUSION_HOME must be set";
my $FUSION_INSPECTOR_HOME = $ENV{FUSION_INSPECTOR_HOME} or die "Error, env var FUSION_INSPECTOR_HOME must be set";


main: {

    ## Save outputs:
    my $ctat_outdir = "ctat_out";
    unless (-d $ctat_outdir) {
        mkdir "$ctat_outdir" or die "Error, cannot mkdir $ctat_outdir";
    }
    

    my $pipeliner = new Pipeliner(-verbose => 2);
    
    my $cmd = "tar xvf $ctat_genome_lib_tar_gz";
    $pipeliner->add_commands(new Command($cmd, "untar_genome_lib.ok"));
    
    ## Run STAR-Fusion
    
    $cmd = "$STAR_FUSION_HOME/STAR-Fusion " .
	" --left_fq  $left_fq_gz" .
	" --right_fq $right_fq_gz" . 
        " --genome_lib_dir CTAT_lib" .
	" --output_dir star_fusion_outdir";

    $pipeliner->add_commands(new Command($cmd, "star_fusion.ok"));
    
    $cmd = "cp star_fusion_outdir/star-fusion.fusion_candidates.final.abridged.FFPM $ctat_outdir";
    #$pipeliner->add_commands(new Command($cmd, "capture_star_fusion_outputs.ok"));
    
    
    if (grep { /FusionInspector/i } @ARGV) {
	## Run FusionInspector
	$cmd = "$FUSION_INSPECTOR_HOME/FusionInspector --fusions star_fusion_outdir/star-fusion.fusion_candidates.final.abridged.FFPM " .
	    " --genome_lib CTAT_lib " .
	    " --left_fq $left_fq_gz " .
	    " --right $right_fq_gz " .
	    " --out_dir Fusion_Inspector-STAR " .
	    " --out_prefix finspector " .
	    " --align_utils STAR --prep_for_IGV --no_cleanup ";
	
	$pipeliner->add_commands(new Command($cmd, "fusion_inspector.ok"));
	
	
	$cmd = "cp Fusion_Inspector-STAR/finspector.fusion_predictions.final.abridged.FFPM $ctat_outdir";
	$pipeliner->add_commands(new Command($cmd, "capture_fusion_inspector_outputs.ok"));
    }
    

    
    ## package up results
    
    $cmd = "tar -zcvf $ctat_outdir.tar.gz $ctat_outdir";
    #$pipeliner->add_commands(new Command($cmd, "package_up_tar.ok"));
    

    $cmd = "find .";
    $pipeliner->add_commands(new Command($cmd, "test_find.ok"));
    
    $pipeliner->run();
    
    
    exit(0);
    
}

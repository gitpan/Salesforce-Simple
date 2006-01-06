use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Salesforce::Simple',
    VERSION_FROM      => 'lib/Salesforce/Simple.pm', # finds $VERSION
    PREREQ_PM         => {Salesforce => 0.54}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Salesforce/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Chase Whitener <cwhitener@gmail.com>') : ()),
);

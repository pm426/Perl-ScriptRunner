use 5.016001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl::ScriptRunner',
    VERSION_FROM      => 'lib/Perl/ScriptRunner.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Carp' => 0,
        'IO::Handle'    => 0,
        'IO::Select'    => 0,
        'POSIX'         => 0,
        'Time::HiRes'   => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'   => 0,
    },
    ABSTRACT_FROM     => 'lib/Perl/ScriptRunner.pm', # retrieve abstract from module
    AUTHOR            => 'pmalek <pmalek426 @ gmail.com>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

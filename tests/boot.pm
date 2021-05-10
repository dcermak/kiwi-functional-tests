# Copyright (C) 2020 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use base "basetest";
use strict;
use testapi;

sub run {
    # we first check whether the bootloader is visible (fails on Fedora for
    # $reasons...)
    my $match = check_screen('kiwi_bootloader', timeout => 10);
    if ((get_var('DISTRI') eq 'fedora') && (defined(get_var('HDD_1'))) && (!defined($match))) {
        record_soft_failure('No visible bootloader in the Fedora disk images');
    } elsif (!defined($match)) {
        die "Did not see the bootloader";
    }

    # Check now whether we have to handle UEFI certificates or whether the
    # bootloader is at the wrong entry.
    # We do this in a second check_screen, to ensure that the matched needle
    # will not be "just" 'kiwi_bootloader'.
    check_screen([qw(kiwi_bootloader_boot_from_hdd trust_uefi_certificates)]);

    if (match_has_tag('trust_uefi_certificates')) {
        die 'trust UEFI certificates screen present, but UEFI is not used' unless defined(get_var('UEFI'));

        send_key('down') if match_has_tag('trust_uefi_certificates_no');

        assert_screen('trust_uefi_certificates_yes');
        send_key('ret');

        assert_screen([qw(kiwi_bootloader kiwi_bootloader_boot_from_hdd)]);
    }

    # for some live images the default selected boot entry is the "Boot from
    # Hard Disk" entry we don't want that, so we need to select the correct
    # entry that says "Install $NAME" to achieve that, we just hit HOME first
    # which gets us to the first entry and then spam down until we get a needle
    # match
    if (match_has_tag('kiwi_bootloader_boot_from_hdd') && defined(get_var('PUBLISH_HDD_1'))) {
        send_key('home');
        send_key_until_needlematch('kiwi_bootloader_install_selected', 'down', 10);
        send_key('ret');
    }

    # wait 10 minutes for the unattended installation and 2 for a regular boot
    # (booting can take a while for appliances based on MicroOS as ignition
    # takes its time)
    my $timeout = defined(get_var('PUBLISH_HDD_1')) ? 600 : 120;
    assert_screen('login_prompt', $timeout);
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

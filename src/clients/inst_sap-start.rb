# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LINUX GmbH. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

# Package:      SAP Installation
# Summary:      Select basic installation profile.
# Authors:      Peter Varkoly <varkoly@suse.com>
#
# $Id$

module Yast
  class InstSapStart < Client
    def main
      textdomain "users"
      Yast.import "Pkg"
      Yast.import "Popup"
      Yast.import "PackagesProposal"
      Yast.import "ProductControl"
      Yast.import "GetInstArgs"
      #MAY BE TODO set the default value
      sles   = false
      sap    = false
      wizard = false
      @sap_control = Pkg.SourceProvideOptionalFile(
        0, # optional
        1,
        "/sap-control.xml"      )

      @caption = _("Choose Operation System Edition")
      @help    = _("<p><b>Select operating system edition</b></p>" +
                   "<p>Option \"SUSE Linux Enterprise Server\" will proceed with the generic installation procedure without pre-selecting SAP-specific software packages.</p>" +
                   "<p>Option \"SUSE Linux Enterprise Server for SAP Applications\" will use an installation workflow tailored for an SAP server, the workflow helps to pre-select SAP-specific software packages, and better partition your hard disk.</p>" +
                   "<p>If you wish to proceed with installing SAP softwares right after installing the operating system, tick the checkbox \"Launch SAP product installation wizard right after operating system is installed\".</p>")
      @contents = VBox(
            RadioButtonGroup(
              Id(:rb),
              VBox(
                Left(Heading(_("Please select the operating system you want to install"))),
                Left(
                  RadioButton(
                    Id("sles"),
                    Opt(:notify),
                    _("SUSE Linux Enterprise Server"),
                    sles
                  )
                ),
                Left(
                  RadioButton(
                       Id("sap"),
                       Opt(:notify),
                       _("SUSE Linux Enterprise Server for SAP Applications"),
                       sap
                     )
                   ),
                Frame("",
                    Left(
                      CheckBox(
                        Id("wizard"),
                        _("Launch SAP product installation wizard right after operating system is installed"),
                        wizard
                      )
                    )
               )
            )
          )
       )
      Wizard.SetDesktopIcon("sap-installation-wizard")
      Wizard.SetContents(
        @caption,
        @contents,
        @help,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )
      UI.ChangeWidget(Id("wizard"),:Enabled,false)
      ret = nil
      begin
        ret = Wizard.UserInput
        Builtins.y2milestone("ret %1",ret)
        case ret
        when :abort
          break if Popup.ConfirmAbort(:incomplete)
        when :help
          Wizard.ShowHelp(@help)
	when "sles"
	  UI.ChangeWidget(Id("wizard"),:Enabled,false)
	when "sap"
	  UI.ChangeWidget(Id("wizard"),:Enabled,true)
        when :next
          install   = Convert.to_string(UI.QueryWidget(Id(:rb), :CurrentButton))
          case install
          when "sap"
	    constumize_sap_installation(Convert.to_boolean( UI.QueryWidget(Id("wizard"), :Value)) )
          when "sles"
	    constumize_sles_installation
          else
            Popup.Error("You have to select one Product Installation Mode!")
            ret = nil
          end
        end
      end until ret == :next || ret == :back
      ret
    end

    def constumize_sap_installation(start_wizard)
        ProductControl.ReadControlFile( @sap_control )
        if(start_wizard)
           PackagesProposal.AddResolvables('sap-wizard',:package,['yast2-firstboot','sap-installation-wizard'])
	   IO.write("/root/start_sap_wizard","true");
           ProductControl.EnableModule("sap")
	else
           PackagesProposal.AddResolvables('sap-wizard',:package,['sap-installation-wizard'])
           PackagesProposal.RemoveResolvables('sap-wizard',:package,['yast2-firstboot'])
           ProductControl.DisableModule("sap")
	end
    end

    def constumize_sles_installation()
        ProductControl.ReadControlFile("/control.xml")
        PackagesProposal.RemoveResolvables('sap-wizard',:package,['yast2-firstboot','sap-installation-wizard'])
        ProductControl.DisableModule("sap")
    end
  end
end

Yast::InstSapStart.new.main


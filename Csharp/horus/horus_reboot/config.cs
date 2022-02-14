using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace horus_reboot
{
    public class config
    {
        public string DefaultLoadModelPath;
        public string DefaultSaveModelPath;

        public int DefaultMeasurement;

        public config()
        {
            /*if (Properties.Settings.Default.LoadDefaultView == null)    // if no settings -> defaultpath -> (no defaultpath || no defaultpath.directory.exists) -> emptypath / desktop
            { DefaultLoadModelPath = pass defaults into local variable  }
            else
            { DefaultLoadModelPath = Properties.Settings.Default.LoadDefaultView; }*/
                
            // on init, if config values mean shit all, boot up <<current defaults>>.
            // YOU NEED TO KEEP IT EMPTY AND JUST USE DEFAULTS, NOT REPLACE CONFIG UNTIL USER DECIDES SO
        }


        //opens an options window to adjust settings
        public void OpenConfigWindow()
        {
            options CurrentOption = new options();
            CurrentOption.ShowDialog();

            if (CurrentOption.DialogResult == true)
            {
                /*save local options as program config options*/
            }
        }

    }
     
    
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace horus_reboot
{
    /// <summary>
    /// Binary question window
    /// </summary>
    public partial class YesNoDialog : Window
    {
        public YesNoDialog(string Infomsg)
        {
            InitializeComponent();
            Msgbox.Text = Infomsg;
            Top = SystemParameters.PrimaryScreenHeight / 2;
            Left = SystemParameters.PrimaryScreenWidth / 2;
        }

        private void yesReply_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = true;
        }

        private void noReply_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = false;
        }
    }
}

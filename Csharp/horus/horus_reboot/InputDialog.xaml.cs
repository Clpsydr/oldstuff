using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Globalization;
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
    /// One-line input box dialog for renaming and such
    /// </summary>
    public partial class InputDialog : Window

    {
        public InputDialog(string question, string topic, string defaultContent)
        {
            InitializeComponent();
            DialogLabel.Text = question;
            InputBox.Text = defaultContent;
            Title = topic;
            Top = SystemParameters.PrimaryScreenHeight / 2;
            Left = SystemParameters.PrimaryScreenWidth / 2;
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = true;
        }

        private void Window_ContentRendered(object sender, EventArgs e)
        {
            InputBox.SelectAll();
            InputBox.Focus();
        }

        public string Answer
        {
            get { return InputBox.Text; }
        }

        public float DigitAnswer //exception is caught during dialog call, not here
        {
            get { return float.Parse(InputBox.Text, CultureInfo.InvariantCulture); } 
        }


    }
}

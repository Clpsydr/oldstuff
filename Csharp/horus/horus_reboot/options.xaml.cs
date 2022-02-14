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
    /// Interaction logic for options.xaml
    /// </summary>
    public partial class options : Window
    {
        public options()
        {
            InitializeComponent();
            //boot up config values into text windows  
            loadpath.Text = Properties.Settings.Default.LoadDefaultView;
            savepath.Text = Properties.Settings.Default.SaveDefaultView;

            //for decimal rounding, just numbers?
            Dictionary<int, String> measurement = new Dictionary<int, String>();
            //for mm/cm split, dictionary with number - string pair. Manage to catch it from xml list somehow! How, willbe easier to understand when you get any value out of app.config at all
        }


        //returns with a save command
        private void savebutton_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = true;
            //put textbox results back into config
        }

        //returns with no particular command
        private void cancelbutton_Click(object sender, RoutedEventArgs e)
        {

        }

        private void savepathchange_Click(object sender, RoutedEventArgs e)
        {
            //open dialog , preferably with current path for loading/saving
            //on closure save it into textboxes
        }

        private void loadphotochange_Click(object sender, RoutedEventArgs e)
        {

        }
    }
}

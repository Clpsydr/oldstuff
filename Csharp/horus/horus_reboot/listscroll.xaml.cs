using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
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
    /// Interaction logic for listscroll.xaml
    /// </summary>
    /// 

    public partial class listscroll : Window, INotifyPropertyChanged
    {
        public MainWindow currentMainWindow;  ///to store the link on loading

        private int gridheightsize = 120;

        public List<view> viewList = new List<view>();             //selection of views that is getting worked on
        private ObservableCollection<measure> defaultmeasures; // current list of measures to check into listview
        public ObservableCollection<measure> DefaultMeasures
        {
            get { return defaultmeasures; }
            set
            {
                if (value != defaultmeasures)
                {
                    defaultmeasures = value;
                    RaisePropertyChanged("defaultmeasures");
                }
            }
        }

        public listscroll()
        {
            this.InitializeComponent();

            defaultmeasures = new ObservableCollection<measure>();                              // adding a datadependency for currentlist

            //MeasureView.DataContext = DefaultMeasures; //wrong instruction?
            MeasureView.ItemsSource = DefaultMeasures;
            RaisePropertyChanged("defaultmeasures");
        }


        /// //
        public event PropertyChangedEventHandler PropertyChanged = delegate { };
        private void RaisePropertyChanged(string propName)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(propName));
        }
        /// //


        public bool IsViewSelected(view currentview)                // checks if the view in question uploaded into main window
        {
            if (currentview.photoUrl == currentMainWindow.GetImgUrl())
                return true;
            else
                return false;
        }

        /// <summary>
        /// returns the selected view record in the listbox
        /// </summary>
        /// <returns></returns>
        public view SelectedView()
        {
            return viewList[viewcontainer.SelectedIndex];
        }

        #region List Operations
        /// <summary>
        /// resets entire listbox and reads every existing view
        /// </summary>
        /// <param name="observedList"></param>
        public void Reload(List<view> observedList)
        {
            viewcontainer.Items.Clear();
            currentMainWindow.UnloadPhoto();

            foreach (view thisview in observedList)
                AddAView(thisview);
            ShowView(observedList.Last());
        }

        /// <summary>
        /// removing selected view and corresponding grid entry
        /// </summary>
        public void RemoveView(view currentview)
        {
            if (viewList.Count > 1)             // if there will be anything else to pick, dont just unload photo
            {
                if (IsViewSelected(currentview))    // is the photo shown selected, show the next one or previous if nothing else after it
                {
                    view nextview;
                    if (viewList.IndexOf(currentview) != viewList.Count - 1)
                        nextview = viewList[viewList.IndexOf(currentview) + 1];
                    else nextview = viewList[viewList.IndexOf(currentview) - 1];
                    ShowView(nextview);
                }
            }
            else
            {
                currentMainWindow.UnloadPhoto();
                MeasureView.DataContext = defaultmeasures;
                MeasureView.ItemsSource = defaultmeasures;
            }

            if (currentview.currentlocation == fileloc.int_file)
                currentMainWindow.BlacklistSend(currentview.filename); //file is marked for deletion, if its the internal file
            else if (currentview.currentlocation == fileloc.ext_file) //if file was removed before saving, throw it away from whitelist
                currentMainWindow.WhitelistClear(currentview.filename);

            viewcontainer.Items.RemoveAt(viewList.IndexOf(currentview));
            viewList.Remove(currentview);

            //TODO remove data binding as well
        }

        public void AddAView(Uri newurl, int position) // generates a view at certain order in the list
        { }

        /// <summary>
        /// generates grid based on already added view
        /// </summary>
        public void AddAView(view currentview)
        {
            Grid newrecord = new Grid();

            newrecord.Height = gridheightsize;
            newrecord.Width = viewcontainer.ActualWidth;
            newrecord.HorizontalAlignment = HorizontalAlignment.Center;
            newrecord.VerticalAlignment = VerticalAlignment.Top;

            RowDefinition row1 = new RowDefinition();               // adding grid rows and columns
            row1.Height = new GridLength(4, GridUnitType.Star);    // 4 to 1 proportion
            RowDefinition row2 = new RowDefinition();
            row2.Height = new GridLength(1, GridUnitType.Star);
            newrecord.RowDefinitions.Add(row1);
            newrecord.RowDefinitions.Add(row2);
            ColumnDefinition col1 = new ColumnDefinition();
            col1.Width = new GridLength(1, GridUnitType.Star);
            newrecord.ColumnDefinitions.Add(col1);

            //TODO: put a whitebg rectangle behind image in the same cell, so user could select photo without clicking on it directly

            Image imggrid = currentview.photoThumb;         // linking img thumb
            imggrid.HorizontalAlignment = HorizontalAlignment.Stretch;
            Grid.SetRowSpan(imggrid, 2);
            Grid.SetRow(imggrid, 0);
            Grid.SetColumn(imggrid, 0);

            TextBlock textgrid = currentview.viewName;        // linking a text
            textgrid.Background = Brushes.White;
            textgrid.Opacity = 0.5;

            Grid.SetRowSpan(textgrid, 2);
            Grid.SetRow(textgrid, 1);
            Grid.SetColumn(textgrid, 0);
            //
            newrecord.Children.Add(imggrid);                //adding transformed data into the grid module
            newrecord.Children.Add(textgrid);

            newrecord.AddHandler(Grid.MouseLeftButtonUpEvent, new RoutedEventHandler(newrecord_MouseLeftButtonUp));   // adding an event for clicking and selecting
            newrecord.AddHandler(Grid.MouseRightButtonDownEvent, new RoutedEventHandler(newrecord_MouseRightButtonDown));  //for selection before context menu!

            viewcontainer.Items.Add(newrecord);             //put grid into listbox as a record
            viewcontainer.SelectedIndex = viewcontainer.Items.Count - 1;
        }

        /// <summary>
        /// generates a view and a gridbox based on added picture
        /// </summary>
        public void AddAView(Uri newurl)
        {
            view freshview = new view(newurl, " ", gridheightsize, fileloc.ext_file);

            RecreateHelpers(freshview);

            viewList.Add(freshview);
            AddAView(freshview);
        }

        /// <summary>
        /// generates a view from loading the data
        /// </summary>
        public void ReloadView(Uri newurl, string name, List<measureproxy> oldmeasurelist)
        {
            view freshview = new view(newurl, name, gridheightsize, fileloc.int_file);
            viewList.Add(freshview);
            AddAView(freshview);

            foreach (measureproxy currentmeasure in oldmeasurelist)
            {
                measuretype temptype = new measuretype();
                if (currentmeasure.measuretype == "measure")
                    temptype = measuretype.measure;
                else if (currentmeasure.measuretype == "helper")
                    temptype = measuretype.helper;

                viewList.Last().restoreAMeasure(currentmeasure.X1, currentmeasure.Y1, currentmeasure.X2, currentmeasure.Y2,
                    currentmeasure.name, currentmeasure.isrealsize, currentmeasure.realvalue, temptype);

                if (currentmeasure.isrealsize == true)
                {
                    viewList.Last().Ethalon = freshview.MeasureList.Last();
                }
            }
        }

        /// <summary>
        /// selects current view, including photo and measure binding
        /// </summary>
        public void ShowView(view thisview)
        {
            DetachView();
            currentMainWindow.LoadPhoto(thisview);

            MeasureView.DataContext = thisview.MeasureList;
            MeasureView.ItemsSource = thisview.MeasureList;

            foreach (measure currentmeasure in thisview.MeasureList)
            {
                currentMainWindow.MeasureFrame.Children.Add(currentmeasure.Ruler);
            }
        }


        /// <summary>
        /// cuts ties with the current view - image, measures and databinding
        /// </summary>
        public void DetachView()
        {
            currentMainWindow.UnloadPhoto();

            var thecanvascollection = currentMainWindow.MeasureFrame.Children.OfType<Shape>();
            while (thecanvascollection.Count() > 0)
            {
                currentMainWindow.MeasureFrame.Children.Remove(thecanvascollection.First());
            }

            MeasureView.ItemsSource = defaultmeasures;
            //TODO deselect data
        }

        /// <summary>
        /// flushes the viewlist and its representation in the listbox
        /// </summary>
        public void Clear()
        {
            DetachView();
            viewcontainer.Items.Clear();
            viewList.Clear();
        }

        #endregion

        #region mouse triggers
        /// <summary>
        /// selecting correct view based on picked grid in the list
        /// </summary>
        void newrecord_MouseLeftButtonUp(object sender, RoutedEventArgs e)
        {
            ShowView(SelectedView());
        }

        void newrecord_MouseRightButtonDown(object sender, RoutedEventArgs e)       // opening context menu for the selected grid item
        {
            //open context menu
        }

        /// <summary>
        /// selects a new standard and recalculates all measures
        /// </summary>
        private void MeasureView_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            if (MeasureView.SelectedItem != null)
            { //MAKE A SEPARATE NUMBER DIALOG
                try
                  {
                      InputDialog setstandarddialog = new InputDialog("задайте новую величину в миллиметрах","установка размера калибра", "0");
                      if (setstandarddialog.ShowDialog() == true)
                          SelectedView().SetUpStandard(MeasureView.SelectedIndex, setstandarddialog.DigitAnswer);
                  }
                  catch
                  {
                      MessageBox.Show("пожалуйста, вводите только числовые значения");
                  }
                //setUpStandard((measure)MeasureView.SelectedItem,setstandarddialog.DigitAnswer);
            }
        }
        #endregion

        /// <summary>
        /// Uses measurelist to switch off all standards in it, set up selected standard and recalculate all sizes in the measurelist
        /// </summary>
        private void setUpStandard(measure standardmeasure, double newrealsize)
        {
            var currentmeasurelist = MeasureView.ItemsSource;
            // MeasureView.SelectedItems
            //NEED TO GET ACTUAL LIST OF ITEMS, NOT DATACONTEXT OR .SELECTEDITEMS. 

            foreach (measure currentmeasure in currentmeasurelist)
            {
                currentmeasure.IsRealSize = false;
                currentmeasure.RealSize = currentmeasure.Size * (newrealsize / standardmeasure.Size);

                //realsize and ethalon nominal size    // realsize of another will be ? 
            }

            standardmeasure.IsRealSize = true;
            standardmeasure.RealSize = newrealsize;
        }

        /// <summary>
        /// returns type of the line, and also selects it in the grid
        /// </summary>
        public measuretype LineLookup(Line lineinquestion)
        {
            if (lineinquestion != null)
            {
                foreach (measure currentmeasure in MeasureView.ItemsSource)
                {
                    if (lineinquestion == currentmeasure.Ruler)
                    {
                        MeasureView.SelectedItem = currentmeasure;
                        return currentmeasure.LineType;
                    }
                }

            }
            return measuretype.measure;
        }

        /// <summary>
        /// looks up helper lines, removes them, and creates a default 4 pair
        /// </summary>
        public void RecreateHelpers(view currentview)
        {
            //looking up through view measures and remove them
            for (int i = currentview.MeasureList.Count; i > 0; i--)
            {
                if (currentview.MeasureList[i - 1].LineType == measuretype.helper)
                    currentview.MeasureList.RemoveAt(i - 1);
            }

            currentview.addAMeasure(5, -currentview.BitmHeight, 5, 2 * currentview.BitmHeight, measuretype.helper);  //math.sqrt(bitmheight*bitmheight + bitmwidth*bitmwidth) for maximal safety
            currentview.addAMeasure(-currentview.BitmWidth, 5, 2 * currentview.BitmWidth, 5, measuretype.helper);
            currentview.addAMeasure(currentview.BitmWidth - 5, -currentview.BitmHeight, currentview.BitmWidth - 5, 2 * currentview.BitmHeight, measuretype.helper);
            currentview.addAMeasure(-currentview.BitmWidth, currentview.BitmHeight - 5, 2 * currentview.BitmWidth, currentview.BitmHeight - 5, measuretype.helper);

            ShowView(currentview);
        }

        public void DeleteLine(Line lineinquestion)
        {
            if (lineinquestion != null)
            {
                foreach (measure currentmeasure in MeasureView.ItemsSource)
                {
                    if (lineinquestion == currentmeasure.Ruler)
                        MeasureView.Items.Remove(currentmeasure);  //will it properly treat collection of the source?
                }

            }

        }

        #region Context commands

        /// <summary>
        /// renaming the selected grid module
        /// </summary>
        private void RenameRclick(object sender, EventArgs e)
        {
            string defaultname = viewList[viewcontainer.SelectedIndex].viewName.Text;
            InputDialog renameDialog = new InputDialog("введите новое название размера: ","переименование размера", defaultname);
            if (renameDialog.ShowDialog() == true)
            {
                //currentMainWindow.viewList[viewcontainer.SelectedIndex].viewName = renameDialog.Answer; //can you use only "defaultname" there?
                viewList[viewcontainer.SelectedIndex].viewName.Text = renameDialog.Answer;
            }
        }

        /// <summary>
        /// Removing selected view module
        /// </summary>
        private void RemoveRclick(object sender, EventArgs e)
        {
            RemoveView(viewList[viewcontainer.SelectedIndex]);

        }

        private void SetUpEthalon(object sender, EventArgs e)
        {
            if (MeasureView.SelectedItem != null)
            { //MAKE A SEPARATE NUMBER DIALOG
                try
                {
                    InputDialog setstandarddialog = new InputDialog("Введите реальный размер в миллиметрах", "установка величины калибра", "0");
                    if (setstandarddialog.ShowDialog() == true)
                        SelectedView().SetUpStandard(MeasureView.SelectedIndex, setstandarddialog.DigitAnswer);
                }
                catch
                {
                    MessageBox.Show("пожалуйста, вводите только числовые значения");
                }
                //setUpStandard((measure)MeasureView.SelectedItem,setstandarddialog.DigitAnswer);
            }


        }


        /// <summary>
        /// Reattach the whole viewlist DEPRECATED
        /// </summary>
        private void Reloadclick(object sender, EventArgs e)
        {
            Reload(viewList);
        }

        /// <summary>
        /// Open view measures dialog to rename or change type
        /// </summary>
        private void MeasureOptionsRclick(object sender, EventArgs e)
        {
            //currently only renaming
            try
            {
                measure selectedmeasure = (measure)MeasureView.SelectedItem;
                InputDialog renameDialog = new InputDialog("Введите новое название размера: ", "переименование размера", selectedmeasure.Name);
                if (renameDialog.ShowDialog() == true)
                    selectedmeasure.Name = renameDialog.Answer;
            }
            catch (NullReferenceException)
            {
                
            }
        }

        /// <summary>
        /// Deletes currently selected measure line
        /// </summary>
        private void RemoveMeasureRclick(object sender, EventArgs e)
        {
            //
            // pointed out record in measureview should delete corresponding record in the list (only if order is the same, and it doesnt skip any records or changes sorting)
            //
            try
            {
                viewList[viewcontainer.SelectedIndex].MeasureList.RemoveAt(MeasureView.SelectedIndex);
                currentMainWindow.MeasureFrame.UpdateLayout();
                ShowView(SelectedView());
            }
            catch (ArgumentOutOfRangeException)
            {
                //MessageBox.Show("Aim better next time");
            }

        }

        /*    private void IssueMeasureRclick(object sender, EventArgs e)
            {
                if (MeasureView.SelectedItem != null)
                { 
                    InputDialog setstandarddialog = new InputDialog("set up the real value in millimeters", "0");
                    if (setstandarddialog.ShowDialog() == true)
                        SelectedView().SetUpStandard(MeasureView.SelectedIndex, setstandarddialog.DigitAnswer);
                    //setUpStandard((measure)MeasureView.SelectedItem,setstandarddialog.DigitAnswer);
                }
            }*/
        #endregion


        // item list already does this, but in case you will need it somewhere else, you have to know how
        void SelectItem()
        {
            //find current grid item in the viewlist and mark it as selected
            //get grid that triggered action
            //find corresponding view in the viewlist
            //select it
        }

        /// <summary>
        /// pick a line in canvas that corresponds to databound selected line
        /// </summary>
        private void MeasureView_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (MeasureView.SelectedIndex != -1)
                SelectedView().ShowCertainLine(MeasureView.SelectedIndex);
        }
    }
}

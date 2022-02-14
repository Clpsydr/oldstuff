using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Xml.Serialization;
using System.Xml.Xsl;

namespace horus_reboot
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    /// 
    public enum editmode { normal, helper };

    public partial class MainWindow : Window
    {
        Point? lastCenterPositionOnTarget;
        Point? lastMousePositionOnTarget;
        Point? lastDragPoint;

        private string demotext = "Программа находится в разработке. Данная версия может быть нестабильна, поэтому рекомендуется использовать ее только с целью ознакомления.";

        private bool creationInit;                         // whether the creation/edit started
        private Point initialPoint;                         //
        private Line currentLineselection;                  // captures line
        private bool firstPoint;                            //is it the first point in line to move or not

        private string AppVersion;                           //version of the current build

        public string saveFilePath;                         //-- full path to a photo folder
        public string saveFileName;                         //-- filename.xml
        private string ModelName;                           //loaded model

        private int currentTool = 1;                        //tool selector defines which tool triggers on clicking
        private editmode toolmode;

        private Cursor currentCursor = Cursors.Arrow;       //image representing a tool

        static listscroll listScroll = new listscroll();    // window to display and control views
        config ConfigManager = new config();                // class that allows to do related stuff on setting change events.


        List<string> importjournal = new List<string>();  ///list of filepaths for external photos. 
            //on saving change all photos in it to internal, copy , and link copied filenames

        List<string> deletionjournal = new List<string>(); ///list of filepaths for view deletion
        //on saving marked photos will be deleted from local folder. Only removed view internal photos get there.

        //Would you actually need more info for those lists? To compare accurately?

        public MainWindow()
        {
            InitializeComponent();

            ScrollPort.ScrollChanged += OnScrollViewerScrollChanged;
            ScrollPort.MouseLeftButtonUp += OnMouseLeftButtonUp;
            ScrollPort.PreviewMouseLeftButtonUp += OnMouseLeftButtonUp;
            ScrollPort.PreviewMouseWheel += OnPreviewMouseWheel;

            ScrollPort.PreviewMouseLeftButtonDown += OnMouseLeftButtonDown;
            ScrollPort.MouseMove += OnMouseMove;
            ScrollPort.MouseDoubleClick += OnMouseLeftClick;

            ZoomSlider.ValueChanged += OnSliderValueChanged;

            ScrollPort.Cursor = currentCursor;
            radio_Zoom.IsChecked = true;
            creationInit = false;

            //this window position
            Width = SystemParameters.PrimaryScreenWidth * 0.7;
            Height = SystemParameters.PrimaryScreenHeight - 40;
            Top = 0;
            Left = 0;

            // opening extra windows from the start
            listScroll.Activate();
            listScroll.Top = 0;
            listScroll.Left = SystemParameters.PrimaryScreenWidth * 0.7;
            listScroll.currentMainWindow = this;
            listScroll.Show();
            listScroll.Height = SystemParameters.PrimaryScreenHeight - 40;

            saveFilePath = "";
            AppVersion = "0.8";
            ModelName = "Модель без названия";
            DisableTools();

            //StartAnnounce(); //warning disclaimer

            //something about confirgure
            //make a new class instance
            //load file if its present, if not , construct default

            // a dialog window that lets you do stuff in it

        }

        //debug exception



        /// end


        #region mouse triggers

        // REQUIRES DOUBLE CLICK AND ONLY WORKS WITH THIRD TOOL?
        void OnMouseLeftClick(object sender, MouseButtonEventArgs e)
        {
            currentLineselection = GetCanvasHoveredElement() as Line;
            listScroll.LineLookup(currentLineselection);
        }

        // DOESNT ACTIVATE ?
        void MainWindow1_KeyDown(object sender, KeyEventArgs e)
        {

            if (e.Key == Key.Delete)
                listScroll.DeleteLine(currentLineselection);
        }

        //keyboard DEL press? 
        //if line is selected 
        //use dialog window
        //to remove the line 

        void OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e) //gets dragging capture in scroll window when user holds the button.
        {
            Point mousePos; // This point is captured from different element, depending on mode. For points, its measureframe;

            switch (currentTool)
            {
                case 1:             // dragging capture

                    mousePos = e.GetPosition(ScrollPort);

                    if (mousePos.X <= ScrollPort.ViewportWidth && mousePos.Y < ScrollPort.ViewportHeight) //make sure we still can use the scrollbars
                    {
                        ScrollPort.Cursor = Cursors.SizeAll;
                        lastDragPoint = mousePos;
                        Mouse.Capture(ScrollPort);
                    }
                    break;
                case 2:             // line initialization

                    mousePos = e.GetPosition(MeasureFrame);
                    if (creationInit == false)
                    {
                        if (mousePos.X <= MeasureFrame.Width && mousePos.Y < MeasureFrame.Height)
                        {
                            initialPoint = mousePos;
                            creationInit = true;
                        }

                    }
                    else
                    {
                        if (!Keyboard.IsKeyDown(Key.LeftShift) && !Keyboard.IsKeyDown(Key.RightShift) && (currentLineselection != null))
                        {
                            currentLineselection.X2 = mousePos.X;
                            currentLineselection.Y2 = mousePos.Y;
                        }
                    }
                    break;

                case 3:
                    currentLineselection = GetCanvasHoveredElement() as Line;
                    firstPoint = false;
                    mousePos = e.GetPosition(MeasureFrame);

                    if (currentLineselection != null)
                    {

                        //if clicked on measure, switch to corresponding mode.
                        if (listScroll.LineLookup(currentLineselection) == measuretype.measure)
                        {
                            toolmode = editmode.normal;

                            //getting closest point to the mouse, writing into initialpoint
                            if ((mousePos - new Point(currentLineselection.X1, currentLineselection.Y1)).Length < (mousePos - new Point(currentLineselection.X2, currentLineselection.Y2)).Length)
                                firstPoint = true;
                        }
                        else
                        {
                            toolmode = editmode.helper;
                        }

                        lastDragPoint = mousePos;

                    }
                    break;
            }
        }

        void OnMouseMove(object sender, MouseEventArgs e) //if dragged, get current position and calculate the difference. Then do an offset for the scrolling
        {
            Point mousePos;
            switch (currentTool)
            {
                case 1:
                    if (lastDragPoint.HasValue)
                    {
                        mousePos = e.GetPosition(ScrollPort);

                        double dX = mousePos.X - lastDragPoint.Value.X;  //lastdragpoint?
                        double dY = mousePos.Y - lastDragPoint.Value.Y;   // offset minus that difference is incorrect

                        lastDragPoint = mousePos;

                        ScrollPort.ScrollToHorizontalOffset(ScrollPort.HorizontalOffset - dX);
                        ScrollPort.ScrollToVerticalOffset(ScrollPort.VerticalOffset - dY);
                    }
                    break;
                case 2:      //update line second point to be at cursor
                    mousePos = e.GetPosition(MeasureFrame);

                    if ((creationInit) && ((mousePos - initialPoint).Length != 0)) //was there any movement?
                    {
                        if (currentLineselection != null) //if line was already made
                        {

                            currentLineselection.X2 = mousePos.X;
                            currentLineselection.Y2 = mousePos.Y;

                            if (Keyboard.IsKeyDown(Key.LeftShift) || Keyboard.IsKeyDown(Key.RightShift))
                            {
                                if (Math.Abs(currentLineselection.X2 - currentLineselection.X1) < 20)
                                    currentLineselection.X2 = currentLineselection.X1;

                                if (Math.Abs(currentLineselection.Y2 - currentLineselection.Y1) < 20)
                                    currentLineselection.Y2 = currentLineselection.Y1;
                            }
                        }
                        else //make line and remember it
                        {
                            listScroll.SelectedView().addAMeasure(initialPoint.X, initialPoint.Y, mousePos.X, mousePos.Y, measuretype.measure);
                            currentLineselection = listScroll.SelectedView().MeasureList.Last().Ruler;
                            MeasureFrame.Children.Add(listScroll.SelectedView().MeasureList.Last().Ruler);

                            togglemeasure.IsChecked = true;
                        }
                        //if distance increased from 0, and no line, create line
                        //if line is made, update its position
                    }
                    break;
                case 3:
                    mousePos = e.GetPosition(MeasureFrame);

                    //caught line offsets by amount of change was made by cursor difference
                    if (currentLineselection != null)
                    {
                        double dX = mousePos.X - lastDragPoint.Value.X;
                        double dY = mousePos.Y - lastDragPoint.Value.Y;
                        lastDragPoint = mousePos;
                        if (toolmode == editmode.normal)
                        {
                            if (Keyboard.IsKeyDown(Key.LeftShift) || Keyboard.IsKeyDown(Key.RightShift))
                            {
                                currentLineselection.X1 += dX;
                                currentLineselection.Y1 += dY;
                                currentLineselection.X2 += dX;
                                currentLineselection.Y2 += dY;
                            }
                            else
                            {
                                if (firstPoint)
                                {
                                    currentLineselection.X1 += dX;
                                    currentLineselection.Y1 += dY;
                                }
                                else
                                {
                                    currentLineselection.X2 += dX;
                                    currentLineselection.Y2 += dY;
                                }
                            }
                        }
                        else
                        {
                            if (Math.Abs(dX) >= Math.Abs(dY))
                            {
                                currentLineselection.X1 += dX;
                                currentLineselection.X2 += dX;
                            }
                            else if (Math.Abs(dY) > Math.Abs(dX))
                            {
                                currentLineselection.Y1 += dY;
                                currentLineselection.Y2 += dY;
                            }

                        }
                    }
                    break;
            }
        }

        void OnMouseLeftButtonUp(object sender, MouseButtonEventArgs e) // at releasing button, report releasing, clean last reported point
        {
            var mousePos = e.GetPosition(MeasureFrame);
            ScrollPort.Cursor = currentCursor;
            ScrollPort.ReleaseMouseCapture();

            switch (currentTool)
            {
                case 1:
                    lastDragPoint = null;
                    break;
                case 2:
                    listScroll.SelectedView().Refresh();
                    creationInit = false;
                    currentLineselection = null;
                    break;

                case 3:
                    currentLineselection = null;
                    lastDragPoint = null;
                    listScroll.SelectedView().Refresh();

                    break;
            }
        }

        /// <summary>
        /// used to figure out the element under mouse
        /// </summary>
        private UIElement GetCanvasHoveredElement()
        {
            var elems = MeasureFrame.Children.OfType<Line>().Where(e => e.Visibility == Visibility.Visible && e.IsMouseOver);
            return elems.DefaultIfEmpty(null).First();
        }

        void OnPreviewMouseWheel(object sender, MouseWheelEventArgs e)  // Gets mouse position in the window (?) , change zooming value
        {
            lastMousePositionOnTarget = Mouse.GetPosition(ImgContainer);

            if (e.Delta > 0)
            {
                ZoomSlider.Value += 1;
            }
            if (e.Delta < 0)
            {
                ZoomSlider.Value -= 1;
            }

            e.Handled = true;
        }

        void OnSliderValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e) // changed slider values apply to the scale property. Viewport adjusted.
        {
            ImgScale.ScaleX = e.NewValue;
            ImgScale.ScaleY = e.NewValue;

            var centerOfViewport = new Point(ScrollPort.ViewportWidth / 2, ScrollPort.ViewportHeight / 2);
            lastCenterPositionOnTarget = ScrollPort.TranslatePoint(centerOfViewport, ImgContainer);
        }

        void OnScrollViewerScrollChanged(object sender, ScrollChangedEventArgs e) // Dragging scroll controls changes
        {
            if (e.ExtentHeightChange != 0 || e.ExtentWidthChange != 0)
            {
                Point? targetBefore = null;
                Point? targetNow = null;

                if (!lastMousePositionOnTarget.HasValue)
                {
                    if (lastCenterPositionOnTarget.HasValue)
                    {
                        var centerOfViewport = new Point(ScrollPort.ViewportWidth / 2, ScrollPort.ViewportHeight / 2);
                        Point centerOfTargetNow = ScrollPort.TranslatePoint(centerOfViewport, ImgContainer);

                        targetBefore = lastCenterPositionOnTarget;
                        targetNow = centerOfTargetNow;
                    }
                }
                else
                {
                    targetBefore = lastMousePositionOnTarget;
                    targetNow = Mouse.GetPosition(ImgContainer);

                    lastMousePositionOnTarget = null;
                }

                if (targetBefore.HasValue) //changed values force the scrollport to move
                {
                    double dXInTargetPixels = targetNow.Value.X - targetBefore.Value.X;
                    double dYInTargetPixels = targetNow.Value.Y - targetBefore.Value.Y;

                    double multiplicatorX = e.ExtentWidth / ImgContainer.Width;
                    double multiplicatorY = e.ExtentHeight / ImgContainer.Height;

                    double newOffsetX = ScrollPort.HorizontalOffset - dXInTargetPixels * multiplicatorX;
                    double newOffsetY = ScrollPort.VerticalOffset - dYInTargetPixels * multiplicatorY;

                    if (double.IsNaN(newOffsetX) || double.IsNaN(newOffsetY))
                    {
                        return;
                    }

                    ScrollPort.ScrollToHorizontalOffset(newOffsetX);
                    ScrollPort.ScrollToVerticalOffset(newOffsetY);
                }
            }
        }

        #endregion

        #region property Gets


        private ScaleTransform GetScaleTransform(UIElement element)
        {
            return (ScaleTransform)((TransformGroup)element.RenderTransform).Children.First(tr => tr is ScaleTransform);
        }

        public Uri GetImgUrl()                          // returns URL of the image uploaded
        {
            BitmapImage tempimg = (BitmapImage)MainImageFrame.Source;
            return tempimg.UriSource;
        }

        #endregion

        public void UnloadPhoto()
        {
            MainImageFrame.Source = new BitmapImage();
        }

        public void StartAnnounce() //startupannouncement
        {
            MessageBox.Show(demotext, "Внимание!");
        }


        #region Menu commands

        /// <summary>
        /// New file menu command
        /// </summary>
        private void newFile_Click(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
            {

                YesNoDialog confirmation = new YesNoDialog("Текущая модель будет потеряна без сохранения. Продолжить?");
                if (confirmation.ShowDialog() == true)
                    NewModelCreation();
            }
            else
                NewModelCreation();
        }

        /// <summary>
        /// Cleans up states and generates a new model
        /// </summary>
        private void NewModelCreation()
        {
            CleanUp();
            DisableTools();

            renameModel(true);
            renamecommand.IsEnabled = true;
        }
        /// <summary>
        /// saving menu command
        /// </summary>
        private void saveFile_Click(object sender, RoutedEventArgs e)
        {
            if (saveFilePath == "")
                SaveCurrentModel();
            else
                SaveCurrentModel(saveFilePath + ".xml");
        }

        /// <summary>
        /// Unconditional offer to new filepath 
        /// </summary>
        private void saveFileAs_Click(object sender, RoutedEventArgs e)
        {
            ///externalize all photos. Like (if viewlist not empty, turn them all into external and put into list)


            SaveCurrentModel();
        }

        /// <summary>
        /// Opens set of views and photos from a path
        /// </summary>
        private void loadFile_Click(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
            {
                YesNoDialog confirmation = new YesNoDialog("Текущая модель будет потеряна без сохранения. Продолжить?");
                if (confirmation.ShowDialog() == true)
                    LoadCurrentModel();
            }
            else
            {
                LoadCurrentModel();
            }
        }

        /// <summary>
        /// allow to rename current model
        /// </summary>
        private void renameModel_Click(object sender, RoutedEventArgs e)
        {
            renameModel(false);
        }

        private void renameModel(bool withdefault)
        {

            InputDialog newNameDialog = new InputDialog("Введите имя для предмета: ","общее название модели ", ModelName);
            if (newNameDialog.ShowDialog() == true)
            {
                ModelName = newNameDialog.Answer;
                listScroll.Title = "виды для модели: " + ModelName;
            }
            else if (withdefault)
            {
                MessageBox.Show("модель названа по умолчанию");
                ModelName = "Предмет";
            }
        }

        /// <summary>
        /// basic routine for exiting 
        /// </summary>
        private void exitsoft_Click(object sender, RoutedEventArgs e)
        {
            YesNoDialog confirmdialog = new YesNoDialog("Несохраненные данные будут утеряны. Завершить работу программы?");
            if (confirmdialog.ShowDialog() == true)
            {
                listScroll.Close();
                Close();
            }
        }


        /// <summary>
        /// Initial state, with no views of measures avialable
        /// </summary>
        private void CleanUp()
        {
            saveFilePath = "";
            UnloadPhoto();
            listScroll.Clear();
            CancelLists();
        }

        /// <summary>
        /// external photos in whitelist get local path and copied
        /// internal photos from blacklist get deleted in the savephoto folder
        /// </summary>
        private void ResolveLists()
        {
            foreach (string currentfilename in deletionjournal)
            {
                if (System.IO.Directory.GetFiles(saveFilePath, currentfilename).Count() > 0)
                {
                    try
                    {                                                                                                           //YOU SHOULD BE ABLE TO FIND A SOLUTION TO BLOCKAGE
                        System.IO.File.Delete(saveFilePath + "/" + currentfilename);
                    }
                    catch (IOException)
                    {

                    }
                }
            }

            foreach (string currentpath in importjournal)
            {
                foreach (view currentview in listScroll.viewList)
                {
                    if (currentview.photoUrl.LocalPath == currentpath)
                    {
                        currentview.photoUrl = new Uri("file:///" + saveFilePath + "/" + currentview.filename);
                        currentview.filename = currentview.photoUrl.Segments.Last();
                        File.Copy(currentpath, currentview.photoUrl.LocalPath, true);
                    }
                }
            }
        }

        public void WhitelistSend(string filepath)
        {
            importjournal.Add(filepath);
        }

        public void WhitelistClear(string filepath)
        {
            foreach (string whiterecord in importjournal)
            {
                if (whiterecord == filepath)
                    importjournal.Remove(whiterecord);
            }
        }

        public void BlacklistSend(string filename)
        {
            deletionjournal.Add(filename);
        }

        /// <summary>
        /// Forgets about any changes to lists without action
        /// </summary>
        public void CancelLists()
        {
            importjournal.Clear();
            deletionjournal.Clear();
        }

        /// <summary>
        /// serialization
        /// </summary>
        private void SaveCurrentModel()
        {
            SaveFileDialog freshsave = new SaveFileDialog();
            freshsave.DefaultExt = ".xml";
            freshsave.Filter = "Xml files(.xml)|*.xml";

            if (freshsave.ShowDialog() == true)
            {
                AlienatePhotos();

                saveFileName = freshsave.SafeFileName;
                SaveCurrentModel(freshsave.FileName);
            }
        }

        /// <summary>
        /// Turns photo states in external for resaving
        /// </summary>
        private void AlienatePhotos()
        {
            foreach (view currentview in listScroll.viewList)
            {
                currentview.currentlocation = fileloc.ext_file;
                WhitelistSend(currentview.photoUrl.LocalPath);
            }
        }

        /// <summary>
        /// throwing params to proxy class from particular measure
        /// </summary>
        private void DumpMeasure(measure currentmeasure, measureproxy newmeasure)
        {
            newmeasure.X1 = currentmeasure.Ruler.X1;
            newmeasure.X2 = currentmeasure.Ruler.X2;
            newmeasure.Y1 = currentmeasure.Ruler.Y1;
            newmeasure.Y2 = currentmeasure.Ruler.Y2;
            newmeasure.name = currentmeasure.Name;
            newmeasure.measuretype = currentmeasure.LineType.ToString();
            newmeasure.isrealsize = currentmeasure.IsRealSize;
            newmeasure.realvalue = currentmeasure.RealSize;
        }

        /// <summary>
        /// serialization through already existing path
        /// </summary>
        private void SaveCurrentModel(string filepath)
        {
            //just externalize the dialog and inject filepath from dialog
            TextWriter write = new StreamWriter(filepath); //filepath should be filepath.xml

            Uri helpfuluri = new Uri(filepath);

            Model processinglist = new Model(); //dumping into xml tempclass here
            processinglist.modelname = ModelName;
            processinglist.filepath = filepath.Remove(filepath.Count() - 4); //path to catalogue excluding extension
            processinglist.version = AppVersion;
            processinglist.foldername = helpfuluri.Segments[helpfuluri.Segments.Count()-1].ToString(); //should return segment for relative pathing - last catalogue only
            processinglist.foldername = processinglist.foldername.Remove(processinglist.foldername.Count() - 4);

            processinglist.proxylist = new List<viewproxy>();

            string savepath = processinglist.filepath; //actually this should be last part of filepath, if it was dialogue

            if (!System.IO.Directory.Exists(savepath))
                Directory.CreateDirectory(savepath);

            saveFilePath = processinglist.filepath;

            foreach (view currentview in listScroll.viewList)
            {
                viewproxy freshview = new viewproxy();

                //copying files close to the saved .xml
                string sourceFile = currentview.photoUrl.AbsolutePath;
                string destinationFile = savepath + @"\" + currentview.filename;

                freshview.Url = processinglist.foldername + "/" + currentview.filename;
                //////////////////////////////*dont get %20 on import there  */

                freshview.filename = currentview.filename;


                freshview.name = currentview.viewName.Text;
                freshview.bitmwidth = currentview.BitmWidth;
                freshview.bitmheight = currentview.BitmHeight;

                if (currentview.Ethalon != null)
                {
                    freshview.standardmeasure = new measureproxy();
                    DumpMeasure(currentview.Ethalon, freshview.standardmeasure);
                }

                freshview.measurelist = new List<measureproxy>();
                foreach (measure currentmeasure in currentview.MeasureList)
                {
                    measureproxy freshmeasure = new measureproxy();
                    DumpMeasure(currentmeasure, freshmeasure);
                    freshview.measurelist.Add(freshmeasure);
                }
                processinglist.proxylist.Add(freshview);

                currentview.currentlocation = fileloc.int_file;
            }
            //end dumping

            XmlSerializer s = new XmlSerializer(typeof(Model));
            s.Serialize(write, processinglist);
            write.Close();

            ResolveLists();
            MessageBox.Show("Сохранение прошло успешно!");
            this.MainWindow1.Title = "Виды модели: " + saveFilePath;

            //
        }

        /// <summary>
        /// deserialization
        /// </summary>
        private void LoadCurrentModel()
        {
            CleanUp();
            OpenFileDialog openfile = new OpenFileDialog();
            openfile.DefaultExt = ".xml";
            openfile.Filter = "Xml files(.xml)|*.xml";

            if (openfile.ShowDialog() == true)
            {
                EnableTools();
                saveFileName = openfile.SafeFileName; //necessary to know which file was used.
                Model processinglist = new Model();

                //                List<viewproxy> freshview = new List<viewproxy>();

                XmlSerializer loader = new XmlSerializer(typeof(Model));
                FileStream newstream = new FileStream(openfile.FileName, FileMode.Open);
                processinglist = (Model)loader.Deserialize(newstream);
                ModelName = processinglist.modelname;

                AppVersion = processinglist.version;            // in future, compare versions and extract them with caution

                saveFilePath = openfile.FileName.Remove(openfile.FileName.Count() - 4);

                foreach (viewproxy currentview in processinglist.proxylist)         //creating actual views 
                {
                    //WebUtility.HtmlDecode( didnt help , doesn't affect it. HtmlUtility supposed to but doesnt exist at all
                    //MessageBox.Show(String.Format("{0} = {1}", currentview.filename, currentview.filename.Replace("%20", " ")));
                    string tempstring = saveFilePath + "/" + currentview.filename.Replace("%20", " ");
                    listScroll.ReloadView(new Uri(tempstring), currentview.name, currentview.measurelist);   //uses system loaded filepath with catalog + filename
                }

                listScroll.ShowView(listScroll.viewList.Last());
                newstream.Close();

                listScroll.Title = "Виды модели: " + ModelName;
                MessageBox.Show("Файл успешно загружен!");
                this.MainWindow1.Title += ": " + saveFilePath;
                renamecommand.IsEnabled = true;
            }
        }

        /// <summary>
        /// adds a view by selecting a photo
        /// </summary>
        private void addView_Click(object sender, RoutedEventArgs e)
        {
            if (renamecommand.IsEnabled == false)                                                   //rename model in case it was just started
            {
                renameModel(true);
            }

            OpenFileDialog GettingNewImage = new OpenFileDialog();
            GettingNewImage.DefaultExt = ".jpg";
            GettingNewImage.Filter = "Изображения(*.jpg; *.png; *.bmp)|*.JPG; *.PNG; *.BMP" + "|Все файлы (*.*)|*.*";

            if (GettingNewImage.ShowDialog() == true)
            {
                EnableTools();
                Uri source;

                source = new Uri(GettingNewImage.FileName);                                         //adding generates external view always, sent to whitelist
                WhitelistSend(GettingNewImage.FileName);

                listScroll.AddAView(source);
                listScroll.ShowView(listScroll.viewList.Last());

                renamecommand.IsEnabled = true;
            }
        }

        private void showViewWindow_Click(object sender, RoutedEventArgs e)
        {
            if (listScroll.IsVisible == false)
            {
                listScroll.Show();
                listScroll.Focus();
                listScroll.WindowState = WindowState.Normal;
            }
            else
                listScroll.Hide();
        }

        /// <summary>
        /// parses xml save file and makes html based on xsl in the same directory as xml.
        /// </summary>
        private void XslExportWide_Click(object sender, RoutedEventArgs e)
        {
            if (savecheck())
                xslexport(System.IO.Directory.GetCurrentDirectory() + @"..\Xsltemplates\wide1page.html");
        }

        private void XslExportThree_Click(object sender, RoutedEventArgs e)
        {
            if (savecheck())
                xslexport(System.IO.Directory.GetCurrentDirectory() + @"..\Xsltemplates\output3page.html");
        }

        private void xslshortexport_Click(object sender, RoutedEventArgs e)
        {
           if (savecheck())
                xslexport(System.IO.Directory.GetCurrentDirectory() + @"..\Xsltemplates\kamisout.html");
        }

        private void xslexport(string xslt_path)
        {
            // TODO:: needs trycatch composition for invalid url, either there or onclick event

            string SaveDirectory = saveFilePath + ".html";

            XslCompiledTransform transform = new XslCompiledTransform();
            transform.Load(xslt_path);
            transform.Transform(saveFilePath + ".xml", SaveDirectory);

            //launching result in the browser
            Process tolaunchhtml = new Process();
            tolaunchhtml.StartInfo.FileName = SaveDirectory;
            tolaunchhtml.Start();
        }

        private bool savecheck()
        {
            if (saveFilePath == "")
            {
                YesNoDialog confirmation = new YesNoDialog("Текущая модель не сохранена в файл! Сохранить и продолжить?");
                if (confirmation.ShowDialog() == true)
                {
                    SaveCurrentModel(saveFilePath);
                    return true;
                }
                else return false;
            }
            else return true;
        }
        #endregion

        public void LoadPhoto(view currentview)                        //short call for loading the picked photo 
        {
            BitmapImage tempimg = new BitmapImage();

            /// Loads global path for fresh photos, but assembled for ones already saved
            tempimg.BeginInit();
            if (currentview.currentlocation == fileloc.ext_file)
                tempimg.UriSource = currentview.photoUrl;               //because of this, you have to keep photourl full. Change photourl only after turning it to internal
            else if (currentview.currentlocation == fileloc.int_file)
                tempimg.UriSource = new Uri(saveFilePath + "/" + currentview.filename.Replace("%20", " "));

            tempimg.CacheOption = BitmapCacheOption.OnLoad;
            /*tempimg.DecodePixelHeight = currentview.BitmHeight;
            tempimg.DecodePixelWidth = currentview.BitmWidth;*/
            tempimg.EndInit();

            MeasureFrame.Width = tempimg.Width;
            MeasureFrame.Height = tempimg.Height;

            /*MeasureFrame.Width = currentview.BitmWidth;             
            MeasureFrame.Height = currentview.BitmHeight;*/
            MainImageFrame.Source = tempimg;
            MainImageFrame.RenderTransformOrigin = new Point(0.5, 0.5);

            Notify("image uploaded with " + currentview.BitmWidth.ToString() + " width and " + currentview.BitmHeight.ToString() + " height");
        }

        #region side Tools
        private void DisableTools()
        {
            radio_MoveLine.IsEnabled = false;
            radio_Point.IsEnabled = false;
            radio_Zoom.IsEnabled = false;
            HelperCreation.IsEnabled = false;
            togglehelper.IsEnabled = false;
            togglemeasure.IsEnabled = false;
            button_ActFitImage.IsEnabled = false;
        }

        private void EnableTools()
        {
            radio_MoveLine.IsEnabled = true;
            radio_Point.IsEnabled = true;
            radio_Zoom.IsEnabled = true;
            HelperCreation.IsEnabled = true;
            togglehelper.IsEnabled = true;
            togglemeasure.IsEnabled = true;
            button_ActFitImage.IsEnabled = true;

            //autocheck buttons ? somehow

        }

        private void FitImage() //fitting into the current grid size.
        {
            Notify("frame is now " + MeasureFrame.Width + "w and " + MeasureFrame.Height + "h");
            ZoomSlider.Value = 1;
        }

        private void button_ActFitImage_Click(object sender, RoutedEventArgs e)
        {
            FitImage();
        }

        public void Notify(string newtext)      // new message on top of the scrollviewer
        {
            Notificationline.Content = newtext;
        }

        void Select_Tool(int toolnumber)
        {
            currentTool = toolnumber;
        }
        #endregion

        #region Tool management

        private void radio_Zoom_Checked(object sender, RoutedEventArgs e)           // switcing between tools for using the click functions
        {
            Select_Tool(1);
            currentCursor = Cursors.SizeAll;
            ScrollPort.Cursor = currentCursor;
            Notify("switched to zoom mode");
        }

        private void radio_Point_Checked(object sender, RoutedEventArgs e)
        {
            Select_Tool(2);
            currentCursor = Cursors.Cross;
            ScrollPort.Cursor = currentCursor;
            Notify("switched to point mode");
        }

        private void radio_Helper_Checked(object sender, RoutedEventArgs e)
        {
            /*Select_Tool(4);
            currentCursor = Cursors.Pen;
            ScrollPort.Cursor = currentCursor;
            Notify("switch to helper mode");*/
            listScroll.RecreateHelpers(listScroll.SelectedView());
            togglehelper.IsChecked = true;
        }

        private void radio_MoveL_Checked(object sender, RoutedEventArgs e)
        {
            Select_Tool(3);
            currentCursor = Cursors.Hand;
            ScrollPort.Cursor = currentCursor;
            Notify("switched to full movement mode");
        }

        private void MainWindow1_Closed(object sender, EventArgs e)     //consequential closure of all enabled windows
        {
            //TODO confirmation on saving data
            //TODO saving unconfirmed for later work
            listScroll.Close();
        }

        private void MainImageFrame_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            FitImage();
        }


        private void togglemeasure_Checked(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
                foreach (measure currentmeasure in listScroll.SelectedView().MeasureList)
                {
                    if (currentmeasure.LineType == measuretype.measure)
                        currentmeasure.Ruler.Visibility = Visibility.Visible;
                }

        }

        private void togglehelper_Checked(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
                foreach (measure currentmeasure in listScroll.SelectedView().MeasureList)
                {
                    if (currentmeasure.LineType == measuretype.helper)
                        currentmeasure.Ruler.Visibility = Visibility.Visible;
                }
        }

        private void togglemeasure_Unchecked(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
                foreach (measure currentmeasure in listScroll.SelectedView().MeasureList)
                {
                    if (currentmeasure.LineType == measuretype.measure)
                        currentmeasure.Ruler.Visibility = Visibility.Hidden;
                }
        }

        private void togglehelper_Unchecked(object sender, RoutedEventArgs e)
        {
            if (listScroll.viewList.Count > 0)
                foreach (measure currentmeasure in listScroll.SelectedView().MeasureList)
                {
                    if (currentmeasure.LineType == measuretype.helper)
                        currentmeasure.Ruler.Visibility = Visibility.Hidden;
                }
        }




        #endregion

        /// <summary>
        /// Opens a config window.
        /// </summary>
        private void OptionOpen_Click(object sender, RoutedEventArgs e)
        {
            //if you had xml options, use that
            //otherwise it should load in app.config
            ConfigManager.OpenConfigWindow();
        }
    }


}

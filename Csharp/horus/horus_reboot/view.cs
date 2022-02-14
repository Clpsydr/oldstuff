using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Shapes;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using System.Collections.ObjectModel;
using System.Windows.Media;
using System.ComponentModel;
using System.Xml.Serialization;

namespace horus_reboot
{
    public enum fileloc {int_file, ext_file};

    public class view : INotifyPropertyChanged
    {
        public Uri photoUrl;     // path to a photo
        public Image photoThumb;    // small photo thumb for a list
        public TextBlock viewName;  // descriptive name for users, autoissued as view(listsize+1)

        public string filename;  
        public fileloc currentlocation;
        
        public double BitmWidth;
        public double BitmHeight;

        private ObservableCollection<measure> measureList; // contains related vector coords
        public measure Ethalon; //single real value taken from a measurelist

        public view (Uri newurl, string name, int thumbheight, fileloc location)        // constructor
        {
            photoUrl = newurl;

            /*if (location == fileloc.ext_file)
                photoUrl = newurl;
            else
            {
             //ideally, get local loadedfile folder + folder + filename
                string folder = newurl.Segments.ElementAt(newurl.Segments.GetLength(1) - 1);
                photoUrl = new Uri("./" + newurl.Segments. + "/" + newurl.Segments.Last());
            }*/
            
            //WHAT IF YOURE GOING TO PICK ONLY RELATIVE URL, SO IT WILL AUTOMATICALLY COMBINE FROM MODELPATH+FILENAME
                                                //YOU WILL NEED A LOT OF DOUBLE CHECKS EVERYWHERE BUT IN THE END YOU COULD ACTUALLY USE NEWURL FOR HTML
                                                 //ITS ALREADY COMPILED FROM PARTS AT RELOADING
                                                 //SINCE YOURE GETTING LOCATION TYPE, YOU CAN SPLIT BEHAVIOUR
                                                  //BUT CHECK WHERE YOURE USING NEWURL LATER ON

            filename = newurl.Segments.Last();  //only a photo filename to keep , should become free from %20 to be converted properly.
            currentlocation = location;

            BitmapImage imgthumb = new BitmapImage();       
            photoThumb = new Image();

            /// TODO: essential error caused by cyrillic in the filename, but not in the folder name
            ///  solution 1 : way to check viability of the url
            ///  extra 1 : sanitize url on load anyway

            imgthumb.BeginInit();                           // for getting the actual pixel size of the image
            imgthumb.UriSource = newurl;                            //< uri injected there but can't process because of %20 in the name. Its passed from newurl like that.
            imgthumb.CacheOption = BitmapCacheOption.OnLoad;
            imgthumb.EndInit();
            BitmWidth = imgthumb.Width;
            BitmHeight = imgthumb.Height;

                imgthumb = new BitmapImage();
                imgthumb.BeginInit();                           // creating shrunk thumbnail
                imgthumb.UriSource = newurl;
                imgthumb.DecodePixelHeight = thumbheight;
                imgthumb.EndInit();
                photoThumb.Source = imgthumb;

                viewName = new TextBlock();
                if (name == "")
                    viewName.Text = filename.ToString().Remove(filename.ToString().Count() - 4);
                else
                    viewName.Text = name;

                measureList = new ObservableCollection<measure>();
        }

        public Line linegenerated(double x1, double x2, double y1, double y2)
        {
            Line temporaryLine = new Line();
            temporaryLine.StrokeThickness = 1;
            
                temporaryLine.X1 = x1;
                temporaryLine.X2 = x2;
                temporaryLine.Y1 = y1;
                temporaryLine.Y2 = y2;
/*            if (type == measuretype.measure)
            {
            }
            else if (type == measuretype.helper)
            {
                double b = (y1 * y2 - x1 * x2) / (x2 + y1);
                double k = (x1 + b) / y1;

                    temporaryLine.Y1 = k * temporaryLine.X1 + b;
                temporaryLine.Y2 = k * temporaryLine.X2 + b;
            }*/

            return temporaryLine;
        }
        public void addAMeasure(double x1, double y1, double x2, double y2, measuretype linerole)  // adding measure in the list for this view
        {
            ///possible to create line based on the role here! with helper role, it will be stretched alongside the canvas
            ///
            ///b = y2 - ((x1+b)/y1)*x2
            ///
            ///k = (x1+b)/y1
            string extraname;
            if (linerole == measuretype.helper)
                extraname = "габаритная линия";
            else
                extraname = "размер";

            measureList.Add(new measure(linegenerated(x1, x2, y1, y2),
                 extraname+" "+(measureList.Count+1).ToString(), linerole));
        }

        public void restoreAMeasure(double x1, double y1, double x2, double y2, string oldname, bool realsize, double realvalue, measuretype linerole)
        {
            measureList.Add(new measure(linegenerated(x1, x2, y1, y2), oldname, realsize, realvalue, linerole));
        }


        public ObservableCollection<measure> MeasureList
        {
            get { return measureList; }
            set
            {
                if (value != measureList)
                {
                    measureList = value;
                    RaisePropertyChanged("measureList");
                }
            }
        }

        /// <summary>
        /// updating all measure params, including realsize if possible
        /// </summary>
        public void Refresh() 
        {
            foreach (measure currentmeasure in measureList)
            {
                currentmeasure.Size = currentmeasure.getLength();
                if (Ethalon != null)
                    currentmeasure.RealSize = GetRealsize(currentmeasure); // how did you get ethalon calculations once again?
            }
        }

        /// <summary>
        /// record N in measureview gets standard of current value
        /// </summary>
        public void SetUpStandard(int index, double newstandardvalue)
        {
            Ethalon = measureList[index];
            Ethalon.IsRealSize = true;
            Ethalon.RealSize = newstandardvalue;
            Ethalon.Naturalcolor = Brushes.SeaGreen;

            foreach (measure currentmeasure in measureList)
            {
                if (Ethalon != currentmeasure)  //if measure isnt the standard
                {
                    currentmeasure.IsRealSize = false;
                    currentmeasure.RealSize = GetRealsize(currentmeasure);
                    currentmeasure.Naturalcolor = Brushes.Purple;
                }
            }

            Refresh();
        }

        public void ShowCertainLine(int index)
        {
            foreach (measure currentmeasure in measureList)
            {
                if (MeasureList[index] == currentmeasure)
                    currentmeasure.Ruler.Stroke = Brushes.Red;
                else
                    currentmeasure.Ruler.Stroke = currentmeasure.Naturalcolor;
            }
        }

        /// <summary>
        /// return "real" value based on ethalon
        /// </summary>
        public double GetRealsize(measure currentmeasure)
        {
            return currentmeasure.Size * (Ethalon.RealSize / Ethalon.Size);
        }

        /// <summary>
        /// returns a measure that holds given line
        /// </summary>
        public measure RecognizeALine(Line observableline)
        {
            foreach (measure currentmeasure in measureList)
            {
                if (currentmeasure.Ruler == observableline)
                    return currentmeasure;
            }
            return null;
        }

/// ////////////
        public event PropertyChangedEventHandler PropertyChanged;
        private void RaisePropertyChanged(string propName)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(propName));
        }


    }
}

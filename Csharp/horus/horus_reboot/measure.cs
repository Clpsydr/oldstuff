using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Xml.Serialization;

namespace horus_reboot
{
    public enum measuretype { measure, helper }; // line variants

    public class measure : INotifyPropertyChanged
    {

        private Line ruler;
        private bool isrealsize; //Stroke of selected gets different color
        public double Size
        {
            get { return (int)Math.Sqrt(Math.Pow(ruler.X1 - ruler.X2, 2) + Math.Pow(ruler.Y1 - ruler.Y2, 2)); }
            set { getLength(); RaisePropertyChanged("Size"); }
        }
        private string name;
        private double realsize = 0;  //(millimeters initially, but somehow, mention units?) actual size, naturally 0 if not set
        private Brush naturalcolor;
        
        private measuretype linetype;

        public measure(Line newline, string newname, measuretype currenttype)
        {
            name = newname;
            isrealsize = false;
            realsize = 0;

            ruler = newline;
            ruler.MouseEnter += new MouseEventHandler(b_MouseEnter);
            ruler.MouseLeave += new MouseEventHandler(b_MouseLeave);
            linetype = currenttype;


            if (currenttype == measuretype.measure)
            {
                Naturalcolor = Brushes.Purple;
                ruler.Stroke = Brushes.Purple;
            }
            else if (currenttype == measuretype.helper)
            {
                Naturalcolor = Brushes.Blue;
                ruler.Stroke = Brushes.Blue;
                ruler.StrokeDashArray = new DoubleCollection(new double[] { 5, 2 });
            }

        }

        public measure(Line newline, string newname, bool realsizedefinition, double realsizevalue, measuretype currenttype)
        {
            name = newname;
            isrealsize = realsizedefinition;
            realsize = realsizevalue;

            ruler = newline;
            ruler.MouseEnter += new MouseEventHandler(b_MouseEnter);
            ruler.MouseLeave += new MouseEventHandler(b_MouseLeave);
            linetype = currenttype;

            if (currenttype == measuretype.measure)
            {
                Naturalcolor = Brushes.Purple;
                ruler.Stroke = Brushes.Purple;
            }
            else if (currenttype == measuretype.helper)
            {
                List<double> dash = new List<double>() {4,4};
                Naturalcolor = Brushes.Blue;
                ruler.Stroke = Brushes.Blue;
                ruler.StrokeDashArray = new DoubleCollection(new double[] { 5, 2 });  
            }
        }

        public Line Ruler
        {
            get { return ruler; }
            set
            {
                ruler = value;
                RaisePropertyChanged("ruler");
                RaisePropertyChanged("linetype");
                //there goes any sort of derived value, such as REALSIZE
            }
        }

        public string Name
        {
            get { return name;  }
            set
            {
                name = value;
                RaisePropertyChanged("name");
            }

        }

        public double RealSize
        {
            get { return realsize; }
            set {
                   realsize = value;
                    RaisePropertyChanged("realsize");
                }
        }

       public bool IsRealSize
        {
            get { return isrealsize; }
            set
            {
                isrealsize = value;
                RaisePropertyChanged("isrealsize");
                RaisePropertyChanged("EthalonPresense");
            }
        }

        public Brush Naturalcolor
        {
            get { return naturalcolor; }
            set
            {
                naturalcolor = value;
                ruler.Stroke = naturalcolor;
            }
        }

        public Brush EthalonPresense 
        {
            get { if (IsRealSize)
                    return Brushes.Red;
                else
                    return Brushes.WhiteSmoke;
                    }
        }

        public measuretype LineType
        {
            get { return linetype; }
            set { linetype = value; }
        }

        ///
        public event PropertyChangedEventHandler PropertyChanged;
        private void RaisePropertyChanged(string propName)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(propName));
        }
        ///

        public int getLength()   // length of the meausre
        {
            return (int)Math.Sqrt(Math.Pow(ruler.X1 - ruler.X2, 2) + Math.Pow(ruler.Y1 - ruler.Y2, 2));
        }

  
        void b_MouseLeave(object sender, MouseEventArgs e)
        {
            this.ruler.Stroke = Naturalcolor;
            //highlight record in listscroll measureview too!

        }

        void b_MouseEnter(object sender, MouseEventArgs e)
        {
            this.ruler.Stroke = Brushes.Yellow;
        }



    }
}

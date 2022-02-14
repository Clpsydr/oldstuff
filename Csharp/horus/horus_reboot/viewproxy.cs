using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

/// <summary>
/// Simple type classes to transfer parameters to a complex classes
/// </summary>
namespace horus_reboot
{
    [Serializable]
    public class Model
    {
        public string modelname;    // logical name
        public string foldername;  // name of the folder
        public string version;      // program version
        public string filepath;     // full url to the image folder

        public List<viewproxy> proxylist;
    }


    [Serializable]
    public class viewproxy
    {
        public string Url;   //deprecated, because you load from savefilepath + filename. Savefilepath regenerates every time you load into current location
        //missing imgthumb
        public string name;
        public string filename;
        public double bitmwidth;
        public double bitmheight;
        

        public List<measureproxy> measurelist;
        public measureproxy standardmeasure;

        public viewproxy()
        {

        }
    }


    [Serializable]
    public class measureproxy
    {
        public double X1;
        public double Y1;
        public double X2;
        public double Y2;
        public bool isrealsize;
        public double realvalue;
        public string measuretype;

        public string name;

        public measureproxy()
        { }
    }
}

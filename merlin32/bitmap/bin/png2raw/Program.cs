using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace png2c1
{
    class Program
    {
        public class spPalette
        {
            public List<Color> colors = new List<Color>();
        }

        public class spPixels
        {
            public int m_width;
            public int m_height;

            public List<byte> m_pixels = new List<byte>();

            public spPixels(int width, int height, List<byte> pixels)
            {
                m_width  = width;
                m_height = height;
                m_pixels = pixels;
            }
        }


        static void Main(string[] args)
        {
            List<spPalette> pals = new List<spPalette>();
            List<spPixels>  pics = new List<spPixels>();

            Console.WriteLine("png2raw");
            Console.WriteLine("{0}", args.Length);

            foreach(string arg in args)
            {
                String pngPath = arg;
                String palPath = Path.ChangeExtension(pngPath, ".pal");
                //--------------------------------------------------------------
                // Read in the palette file (thanks Pro Motion) 
                Console.WriteLine($"Loading {palPath}");

                spPalette pal = new spPalette();

                using (FileStream palStream = new FileStream(palPath, FileMode.Open, FileAccess.Read))
                {
                    for(int idx = 0; idx < 256; ++idx)
                    {
                        int r = palStream.ReadByte();
                        int g = palStream.ReadByte();
                        int b = palStream.ReadByte();

                        pal.colors.Add(Color.FromArgb(255, r, g, b));
                    }
                }

                // Put it in the list
                pals.Add(pal);

                //--------------------------------------------------------------
                // Read in the image file 
                Console.WriteLine($"Loading {pngPath}");

                using (var image = new Bitmap(System.Drawing.Image.FromFile(pngPath)))
                {
                    //Bitmap image = new Bitmap(pngStream);
                    Console.WriteLine("{0} width={1}, height={2}",pngPath, image.Width, image.Height);

                    List<byte> pixels = new List<byte>();

                    for (int y = 0; y < image.Height; ++y)
                    {
                        for (int x = 0; x < image.Width; ++x)
                        {
                            Color p = image.GetPixel(x,y);

                            int idx0 = GetIndex(ref pal.colors, p);

                            byte pb = (byte)idx0;

                            pixels.Add( pb );
                        }
                    }

                    spPixels pic = new spPixels(image.Width, image.Height, pixels);
                    pics.Add(pic);
                }

            }

            String outPath = Path.ChangeExtension(args[0], ".raw");

            Console.WriteLine("Saving {0}", outPath);

            using (BinaryWriter b = new BinaryWriter(
                File.Open(outPath, FileMode.Create)))
            {
                for (int y = 0; y < 240; ++y)
                {
                    spPixels pix = pics[ 0 ];

                    int pixIndex = 320 * y;

                    // Write out the scanline of pix
                    for (int idx = 0; idx < 320; ++idx)
                    {
                        b.Write((byte)pix.m_pixels[ pixIndex + idx ]);
                    }
                }
            }
        }

        //
        // Get the Closest Matching Palette Index
        //
        static int GetIndex(ref List<Color> pal, Color pixel)
        {
            byte result_index = 0;

            if (pal.Count > 0)
            {
                List<float> dist = new List<float>();

                for (int idx = 0; idx < pal.Count; ++idx)
                {
                    float delta = ColorDelta(pal[idx], pixel);
                    dist.Add(delta);

                    // Make sure the result_index is the one
                    // with the least amount of error
                    if (dist[idx] < dist[result_index])
                    {
                        result_index = (byte)idx;
                    }
                }
            }

            return result_index;
        }

        static float ColorDelta(Color c0, Color c1)
        {
            //  Y=0.2126R+0.7152G+0.0722B
            float r = (c0.R-c1.R);
            r = r * r;
            r *= 0.2126f;

            float g = (c0.G-c1.G);
            g = g * g;
            g *= 0.7152f;

            float b = (c0.B-c1.B);
            b = b * b;
            b *= 0.0722f;

            return r + g + b;
        }

    }
}

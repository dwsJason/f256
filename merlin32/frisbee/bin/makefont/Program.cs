using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace makefont
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

            Console.WriteLine("makefont");
            Console.WriteLine("{0}", args.Length);

            foreach(string arg in args)
            {
                String pngPath = arg;
                //--------------------------------------------------------------
                // Read in the image file 
                Console.WriteLine($"Loading {pngPath}");

                using (var image = new Bitmap(System.Drawing.Image.FromFile(pngPath)))
                {
                    //Bitmap image = new Bitmap(pngStream);
                    Console.WriteLine("{0} width={1}, height={2}",pngPath, image.Width, image.Height);

                    int columns = image.Width/8;
                    int rows    = image.Height/8;

                    Console.WriteLine("{0} x {1}, 8x8 Glyphs, Total={2}", columns, rows, columns*rows);

                    List<byte> pixels = new List<byte>();

                    for (int Row = 0; Row < rows; ++Row)
                    {
						int image_y = Row*8;

                        for (int Column = 0; Column < columns; ++Column)
                        {
							// Grab an 8x8 Block
							int image_x = Column*8;

							for (int tile_y = 0; tile_y < 8; tile_y++)
							{
								byte bits = 0;

								for (int tile_x = 0; tile_x < 8; tile_x++)
								{
									Color p = image.GetPixel(tile_x + image_x,
															 tile_y + image_y);

									bits <<= 1;
									if (IsBright(p))
									{
										bits |= 0x1;
									}
								}

								pixels.Add(bits);
							}

                        }
                    }

                    spPixels pic = new spPixels(columns*8, rows*8, pixels);
                    pics.Add(pic);
                }
            }

            String outPath = Path.ChangeExtension(args[0], ".font");

            Console.WriteLine("Saving {0}", outPath);

            using (BinaryWriter b = new BinaryWriter(
                File.Open(outPath, FileMode.Create)))
            {
				for (int imageIdx = 0; imageIdx < pics.Count; ++imageIdx)
				{
                    spPixels pix = pics[ imageIdx ];

					for (int idx = 0; idx < pix.m_pixels.Count; ++idx)
					{
						b.Write((byte)pix.m_pixels[idx]);
					}
				}
            }
        }

		//
		// Is the pixel 0 or 1
		//
		static bool IsBright( Color pixel )
		{
			int brightness = pixel.R | pixel.G | pixel.B;

			if (brightness >= 128)
			{
				return true;
			}

			return false;
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

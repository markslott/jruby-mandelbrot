require 'rubygems'
require 'complex'
require 'sinatra'
require 'trinidad'
require 'java'

set :server, :trinidad

ESCAPERADIUS = 2


ITERATIONS = 200

BI = java.awt.image.BufferedImage
ImgIO = javax.imageio.ImageIO

def mandelbrot2(z)
  i = 0
  c = z
  while Math.sqrt(z.real ** 2 + z.imaginary ** 2) < ESCAPERADIUS and i < ITERATIONS
    z = z * z + c
    i = i + 1
  end
  colorIndex = 0
  if (i < ITERATIONS)
    #code
    z = z * z + c
    i = i + 1
    z = z * z + c
    i = i + 1
    modulus = Math.sqrt(z.real ** 2 + z.imaginary ** 2)
    mu = i - Math.log(Math.log(modulus)) / ESCAPERADIUS
    colorIndex = mu / ITERATIONS * 768
    if colorIndex >= 767
      colorIndex = 767
    elsif colorIndex < 0
      colorIndex = 0
    end
  end
  
  colorIndex.to_int
end

get '/' do
  redirect "/generate"
end

get '/generate' do
  erb :generate
end

post '/generate' do
  content_type "text/html"
  
  xtiles = "#{params[:xtiles]}".to_i
  ytiles = "#{params[:ytiles]}".to_i
  xpos = "#{params[:xpos]}".to_f
  ypos = "#{params[:ypos]}".to_f
  scale = "#{params[:scale]}".to_f
  width = "#{params[:xtilesize]}".to_i
  height = "#{params[:ytilesize]}".to_i
  
  xscale = scale
  yscale = scale * ytiles / xtiles * height / width
  
  print "xtiles = ",xtiles," ytiles = ",ytiles,"\n"
  table = Array.new(ytiles) { Array.new(xtiles,{}) }
  
  y = 0
  while y < ytiles
    x = 0
    while x < xtiles
      
      table[y][x] = {
        :x => x,
        :y => y,
        :xstart => xscale / xtiles * x + xpos,
        :ystart => yscale / ytiles * (ytiles - y - 1) + ypos,
        :xend => xscale / xtiles * (x + 1) + xpos,
        :yend => yscale / ytiles * (ytiles - y) + ypos,
        :width => width,
        :height => height
      }
      print "table cell is ",table[y][x],"\n"
      x += 1
    end
    y += 1
  end
  puts table
  @rows = table
  erb :grid
end

get '/mandelbrot' do
  
  content_type "image/png"
  
  if request["escaperadius"] != nil
    ESCAPERADIUS = request["escaperadius"].to_i
  end
  
  if request["iterations"] != nil
    ITERATIONS = request["iterations"].to_i
  end
  
  x_start = request["x_start"].to_f
  x_end = request["x_end"].to_f
  y_start = request["y_start"].to_f
  y_end = request["y_end"].to_f
  width = request["width"].to_i
  height = request["height"].to_i
  print "******Computing image: ",x_start,",",y_start," to ",x_end,",",y_end," width: ",width," height: ",height,"\n"
  step_x = (x_end - x_start) / width
  step_y = (y_end - y_start) / height
  
  #create color array
  colors = Array.new(768)
  for c in 0..767
    colorValR, colorValG, colorValB = 0,0,0
    if c >= 512
      #code
      colorValR = c - 512
      colorValG = 255- colorValR
    elsif c >= 256
      colorValG = c - 256
      colorValB = 255 - colorValG
    else
      colorValB = c
    end
    colors[c] = 256 * 256 * colorValR + 256 * colorValG + colorValB
    #print("Color ",c," ",colors[c],"\n")
  end
  
  
  cp = BI.new(width, height, BI::TYPE_INT_RGB);
  
  y_pixel = 0
  
  x = x_start
  y = y_end
 
  
  while y > y_start
    x_pixel = 0
    x = x_start
    while x < x_end
      if y_pixel < height and x_pixel < width
        colorVal = mandelbrot2(Complex(x,y))
        #print(colorVal," ",colors[colorVal]," ",x_pixel,",",y_pixel,"\n")
        cp.setRGB(x_pixel,y_pixel,colors[colorVal])
      end
      x_pixel += 1
      x += step_x
    end
    y_pixel += 1
    y -= step_y
    
  end

  img = java.io.ByteArrayOutputStream.new
  ImgIO.write(cp,"png",img)
  String.from_java_bytes(img.toByteArray)
end

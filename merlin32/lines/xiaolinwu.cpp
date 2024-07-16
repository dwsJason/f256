#include <SDL2/SDL.h>

// SDL stuff
SDL_Window* pWindow = 0;
SDL_Renderer* pRenderer = 0;

// swaps two numbers
void swap(int* a , int* b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

// returns absolute value of number
float absolute(float x)
{
    if (x < 0) return -x;
    else return x;
}

// returns integer part of a floating point number
int iPartOfNumber(float x)
{
    return (int)x;
}

// rounds off a number
int roundNumber(float x)
{
    return iPartOfNumber(x + 0.5);
}

// returns fractional part of a number
float fPartOfNumber(float x)
{
    if (x > 0) return x - iPartOfNumber(x);
    else return x - (iPartOfNumber(x)+1);
}

// returns 1 - fractional part of number
float rfPartOfNumber(float x)
{
    return 1 - fPartOfNumber(x);
}

// draws a pixel on screen of given brightness
// 0 <= brightness <= 1. We can use your own library
// to draw on screen
void drawPixel(int x, int y, float brightness)
{
    int c = 255 * brightness;
    SDL_SetRenderDrawColor(pRenderer, c, c, c, 255);
    SDL_RenderDrawPoint(pRenderer, x, y);
}

void drawAALine(int x0, int y0, int x1, int y1)
{
    int steep = absolute(y1 - y0) > absolute(x1 - x0);

    // swap the co-ordinates if slope > 1 or we
    // draw backwards
    if (steep)
    {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }
    if (x0 > x1)
    {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }

    // compute the slope
    float dx = x1 - x0;
    float dy = y1 - y0;
    float gradient = dy / dx;
    if (dx == 0.0)
        gradient = 1;

    int xpxl1 = x0;
    int xpxl2 = x1;
    float intersectY = y0;

    // main loop
    if (steep)
    {
        int x;
        for (x = xpxl1; x <= xpxl2; x++)
        {
            // pixel coverage is determined by fractional
            // part of y co-ordinate
            drawPixel(iPartOfNumber(intersectY), x,
                rfPartOfNumber(intersectY));
            drawPixel(iPartOfNumber(intersectY) - 1, x,
                fPartOfNumber(intersectY));
            intersectY += gradient;
        }
    }
    else
    {
        int x;
        for (x = xpxl1; x <= xpxl2; x++)
        {
            // pixel coverage is determined by fractional
            // part of y co-ordinate
            drawPixel(x, iPartOfNumber(intersectY),
                rfPartOfNumber(intersectY));
            drawPixel(x, iPartOfNumber(intersectY) - 1,
                fPartOfNumber(intersectY));
            intersectY += gradient;
        }
    }

}

// Driver code
int main(int argc, char* args[])
{

    SDL_Event event;

    // initialize SDL
    if (SDL_Init(SDL_INIT_EVERYTHING) >= 0)
    {
        // if succeeded create our window
        pWindow = SDL_CreateWindow("Anti-Aliased Line ",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            640, 480,
            SDL_WINDOW_SHOWN);

        // if the window creation succeeded create our renderer
        if (pWindow != 0)
            pRenderer = SDL_CreateRenderer(pWindow, -1, 0);
    }
    else
        return 1; // sdl could not initialize

    while (1)
    {
        if (SDL_PollEvent(&event) && event.type == SDL_QUIT)
            break;

        // Sets background color to white
        SDL_SetRenderDrawColor(pRenderer, 255, 255, 255, 255);
        SDL_RenderClear(pRenderer);

        // draws a black AALine
        drawAALine(80, 200, 550, 150);

        // show the window
        SDL_RenderPresent(pRenderer);
    }

    // clean up SDL
    SDL_Quit();
    return 0;
}


/*
function plot(x, y, c) is
    plot the pixel at (x, y) with brightness c (where 0 ? c ? 1)

// integer part of x
function ipart(x) is
    return floor(x)

function round(x) is
    return ipart(x + 0.5)

// fractional part of x
function fpart(x) is
    return x - ipart(x)

function rfpart(x) is
    return 1 - fpart(x)

function drawLine(x0,y0,x1,y1) is
    boolean steep := abs(y1 - y0) > abs(x1 - x0)
    
    if steep then
        swap(x0, y0)
        swap(x1, y1)
    end if
    if x0 > x1 then
        swap(x0, x1)
        swap(y0, y1)
    end if
    
    dx := x1 - x0
    dy := y1 - y0

    if dx == 0.0 then
        gradient := 1.0
    else
        gradient := dy / dx
    end if

    // handle first endpoint
    xend := round(x0)
    yend := y0 + gradient * (xend - x0)
    xgap := rfpart(x0 + 0.5)
    xpxl1 := xend // this will be used in the main loop
    ypxl1 := ipart(yend)
    if steep then
        plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
        plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)
    else
        plot(xpxl1, ypxl1  , rfpart(yend) * xgap)
        plot(xpxl1, ypxl1+1,  fpart(yend) * xgap)
    end if
    intery := yend + gradient // first y-intersection for the main loop
    
    // handle second endpoint
    xend := round(x1)
    yend := y1 + gradient * (xend - x1)
    xgap := fpart(x1 + 0.5)
    xpxl2 := xend //this will be used in the main loop
    ypxl2 := ipart(yend)
    if steep then
        plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
        plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)
    else
        plot(xpxl2, ypxl2,  rfpart(yend) * xgap)
        plot(xpxl2, ypxl2+1, fpart(yend) * xgap)
    end if
    
    // main loop
    if steep then
        for x from xpxl1 + 1 to xpxl2 - 1 do
           begin
                plot(ipart(intery)  , x, rfpart(intery))
                plot(ipart(intery)+1, x,  fpart(intery))
                intery := intery + gradient
           end
    else
        for x from xpxl1 + 1 to xpxl2 - 1 do
           begin
                plot(x, ipart(intery),  rfpart(intery))
                plot(x, ipart(intery)+1, fpart(intery))
                intery := intery + gradient
           end
    end if
end function
*/

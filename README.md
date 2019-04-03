# Elisa-evaluation-script

Latest update: 29.03.2019 

Another dialog box asking if all the standards and locations are the same you only have to input it once. 

Elisa script.R is the regular version and Elisa script L.R is for special people! ^_^ Just download which ever version you want. Also the template file is here for reference.  

## A little about the script:

The script uses an R package called DRC or Dose-Response Curves from Ritz et al. 
It builds a Four Parameter Logistic (4PL) Regression model based on your standard (STD) using the following equation:

![](https://raw.githubusercontent.com/Pestudkaru/Elisa-evaluation-script/master/eq.png)

Note that **a** and **d** will always define the upper and lower asymptotes (horizontals) of the curve. The curve can only be used to calculate concentrations for signals within **a** and **d**. Samples outside that range cannot be calculated.
For more accurate quantification I limited the script to use only you **STD's** max. and min. values (usually within the red lines in the figure below) and it will only extrapolate beyond that if you allow *"out of bound values"*.

<img src="https://raw.githubusercontent.com/Pestudkaru/Elisa-evaluation-script/master/ll4%20equation.png" height="300px" width="400px">

**image from:**
https://stats.stackexchange.com/questions/61144/how-to-do-4-parametric-regression-for-elisa-data-in-r

Both **Elisa Script.R** and **Elisa Script L.R** should be identical with the exception of standard(**STD**) placement. STD is usually on the left side (*"vertical"*) blue or bottom right (*"horizontal"*) green.

<img src="https://raw.githubusercontent.com/Pestudkaru/Elisa-evaluation-script/master/96.jpg" height="240px" width="360px">

In case of Elisa Script L.R the horizontal STD is still in the same place but the *"vertical"* is on the right side (blue).

<img src="https://raw.githubusercontent.com/Pestudkaru/Elisa-evaluation-script/master/96%20L.jpg" height="240px" width="360px">

In all cases the two red wells show where the program expects your blanks to be.

The file *"plate reader output template.xlsx"* shows how you should provide the input data and dilutions. 

**For more information:**

+ https://stats.stackexchange.com/questions/61144/how-to-do-4-parametric-regression-for-elisa-data-in-r
+ http://weightinginbayesianmodels.github.io/poctcalibration/calib_tut4_curve_ocon.html
+ https://www.myassays.com/four-parameter-logistic-regression.html

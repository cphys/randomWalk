(* ::Package:: *)

BeginPackage["randomWalks`"];
 
randWalkList::usage = 
 "randWalkList[standardDeviation,mean,steps]		 
	returns: A table of plots for a single random
	walk which can be used to create an animation.";
	
rndWlkDistancePlot::usage = 
 "rndWlkDistancePlot[standardDeviation,mean,steps_,diskSize_]		 
	returns: A table of plots for a single random
	walk which can be used to create an animation.";
	
displacement::usage = 
 "displacement[standardDeviation,mean,steps_]		 
	returns: The overall displacement after number 
	of steps in a random walk.";
	
mostLikelyDisplacementML::usage = 
 "mostLikelyDisplacementML[standardDeviation,mean,steps,runs]		 
	returns: The most likely displacement selected from a 
			 list of training data";
		
mostLikelyDisplacementFit::usage = 
 "mostLikelyDisplacementFit[standardDeviation,mean,steps,runs]		 
	returns: The most likely displacement selected from a 
			 fitting procedure";



Begin["`Private`"]
      
randWalkList[
	standardDeviation_, mean_,steps_,
    OptionsPattern[{
        frameLabel->{"x-steps","y-steps"},
        plotRange -> {{-5,5},{-5,5}}}]]:=
   Module[{
       randPlotGif,delta,
       \[Sigma]x = standardDeviation[[1]],
       \[Sigma]y = standardDeviation[[2]],
       \[Mu]x = mean[[1]],
       \[Mu]y = mean[[2]],
       st = steps,
       pr = OptionValue[plotRange],
       fl = OptionValue[frameLabel]},
       
       delta[\[Mu]_,\[Sigma]_]:=RandomVariate[NormalDistribution[\[Mu],\[Sigma]]];
       randPlotGif=Accumulate[
       ParallelTable[{delta[\[Mu]x,\[Sigma]x], delta[\[Mu]y,\[Sigma]y]},{st}]];
       Table[
       ListPlot[
       Take[randPlotGif,i],
       PlotTheme->"Detailed",
       FrameLabel->fl,
       PlotRange->pr,
       Joined->True],{i,1,st}]]
   
rndWlkDistancePlot[
    standardDeviation_,
    mean_,
    steps_,
    diskSize_,
    OptionsPattern[{
        diskColors -> {Orange,Purple},
        lineColor -> Blue,
        lineThickness -> .01}]] :=
   Module[{
       delta,PRW,
       \[Sigma]x = standardDeviation[[1]],
       \[Sigma]y = standardDeviation[[2]],
       \[Mu]x = mean[[1]],
       \[Mu]y = mean[[2]],
       st = steps,
       ds = diskSize,
       dc = OptionValue[diskColors],
       lc = OptionValue[lineColor],
       lt = OptionValue[lineThickness]},
       
       delta[\[Mu]_,\[Sigma]_]:=RandomVariate[NormalDistribution[\[Mu],\[Sigma]]];
       PRW=Graphics[
       Line[Accumulate[ParallelTable[{delta[\[Mu]x,\[Sigma]x],delta[\[Mu]y,\[Sigma]y]},{st}]]]];
       Show[
       Graphics[{dc[[1]],Disk[PRW[[1]][[1]][[1]],ds]}],
       Graphics[{dc[[2]],Disk[PRW[[1]][[1]][[Length[PRW[[1]][[1]]]]],ds]}],
       PRW,
       Graphics[{lc,Thickness[lt],Line[{PRW[[1]][[1]][[1]],PRW[[1]][[1]][[Length[PRW[[1]][[1]]]]]}]}]]]
       
displacement[
    standardDeviation_,
    mean_,
    steps_] :=
   Module[{
       delta, rndWlk,distWlked,
       \[Sigma]x = standardDeviation[[1]],
       \[Sigma]y = standardDeviation[[2]],
       \[Mu]x = mean[[1]],
       \[Mu]y = mean[[2]],
       st = steps},              
       delta[\[Mu]_,\[Sigma]_]:=RandomVariate[NormalDistribution[\[Mu],\[Sigma]]];
       rndWlk=Accumulate[Table[{delta[\[Mu]x,\[Sigma]x], delta[\[Mu]y,\[Sigma]y]},{st}]];
       Return[Sqrt[rndWlk[[st]][[1]]^2+rndWlk[[st]][[2]]^2]]]
       
mostLikelyDisplacementML[
    standardDeviation_,
    mean_,
    steps_,
    runs_] :=
   Module[{
       displacementList,
       trainingData,sp,
       distWlked,
       \[Sigma]x = standardDeviation[[1]],
       \[Sigma]y = standardDeviation[[2]],
       \[Mu]x = mean[[1]],
       \[Mu]y = mean[[2]],
       st = steps,
       rn = runs},              
       displacementList=Table[displacement[{\[Sigma]x,\[Sigma]y},{\[Mu]x,\[Mu]y},st],{rn}];
       trainingData=Table[i->displacementList[[i]],{i,rn}];
       sp=Predict[trainingData,TrainingProgressReporting->None,PerformanceGoal->"Quality"];
       sp[st+1]]
       
mostLikelyDisplacementFit[
        standardDeviation_,
        mean_,
        steps_,
        runs_,
    OptionsPattern[{
      plotRange -> False,
      tval -> 1,
      workingPrecision -> 64}]] :=
     Module[{
        displacementList,delta,
        sp,
        maxes, plt, xRange,DistWalked,
        distParam, fitFunct,
        \[Sigma]x = standardDeviation[[1]],
        \[Sigma]y = standardDeviation[[2]],
        \[Mu]x = mean[[1]],
        \[Mu]y = mean[[2]],
        st = steps,
        rn = runs,
        pr = OptionValue[plotRange],
        tv = OptionValue[tval],
        wp = OptionValue[workingPrecision]},
        sp[numb_] := SetPrecision[numb, wp];
        
        displacementList = 
        Table[displacement[{\[Sigma]x, \[Sigma]y}, {\[Mu]x, \[Mu]y}, st], {rn}];
          
        distParam = FindDistributionParameters[
          displacementList,
          HyperbolicDistribution[\[Alpha], \[Beta], \[Delta], mu],
          WorkingPrecision->wp];
           
        fitFunct = 
        PDF[HyperbolicDistribution[\[Alpha], \[Beta], \[Delta], mu]/.distParam, x];
        (*\[ScriptCapitalH] = DistributionFitTest[displacementList, Automatic, "HypothesisTestData"];
        fitFunct = PDF[\[ScriptCapitalH]["FittedDistribution"], x];*)
  
        maxes = FindMaximum[fitFunct, {x, 4}]; 
        xRange = {0, 4*maxes[[2]][[1]][[2]]};
        pr = If[pr, {xRange, Full}, {xRange, Full}, pr];
        plt = Show[
        Histogram[displacementList, 100, "PDF",
           PlotRange -> All,
           ChartElementFunction -> "Rectangle",
           ImageSize -> 500,
           LabelStyle -> {FontSize -> 22},
           FrameLabel -> {"Displacement", "Probability"},
           PlotTheme -> "Scientific"],
           Plot[fitFunct, {x, 1, xRange[[2]]},
           PlotStyle -> Red,
           ImageSize -> 500,
           LabelStyle -> {FontSize -> 22}],
           Graphics[{Blue, Dashed, 
            Line[{{maxes[[2]][[1]][[2]], 0},{maxes[[2]][[1]][[2]],maxes[[1]]}}]}],
          PlotRange -> All];
       Return[{
         maxes,
         Labeled[ plt, 
         "\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\) = " <> ToString[\[Sigma]x] <> 
         "  |  \!\(\*SubscriptBox[\(\[Sigma]\), \(y\)]\) = " <> 
         ToString[\[Sigma]y] <> "  |  steps = " <> ToString[IntegerPart@st] <> 
         "  |  runs = " <> ToString[IntegerPart@rn],
         {Top, Left}]}]]


End[]
EndPackage[]

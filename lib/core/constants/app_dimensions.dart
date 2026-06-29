import 'dart:ui';

class AppDimensions {
  AppDimensions._();

  // ── Semantic Spacing & Sizing Multipliers ──
  // Used with screen width (e.g. size.width * AppDimensions.paddingSmall)
  static const paddingXS = numD01; // 1% of screen width
  static const paddingSmall = numD02; // 2% of screen width
  static const paddingMedium = numD04; // 4% of screen width
  static const paddingLarge = numD06; // 6% of screen width
  static const paddingXL = numD08; // 8% of screen width

  // Border Radii Multipliers
  static const radiusSmall = numD02; // 2% of screen width
  static const radiusMedium = numD04; // 4% of screen width
  static const radiusLarge = numD06; // 6% of screen width

  // Font Size Multipliers
  static const fontSizeXS = numD024; // 2.4% of screen width
  static const fontSizeSmall = numD03; // 3% of screen width
  static const fontSizeMedium = numD031; // 3.5% of screen width
  static const fontSizeMedium2 = numD036; // 3.5% of screen width
  static const fontSizeLarge = numD04; // 4% of screen width
  static const fontSizeXL = numD05; // 5% of screen width

  // ── Screen Width Multipliers (Fractional Decimals) ──
  // Typically used as: MediaQuery.of(context).size.width * AppDimensions.numDxxx
  static const numD002 = 0.002;
  static const numD003 = 0.003;
  static const numD004 = 0.004;
  static const numD005 = 0.005;
  static const numD0055 = 0.0055;
  static const numD006 = 0.006;
  static const numD008 = 0.008;
  static const numD009 = 0.009;
  static const numD01 = 0.01;
  static const numD012 = 0.012;
  static const numD013 = 0.013;
  static const numD014 = 0.014;
  static const numD015 = 0.015;
  static const numD016 = 0.016;
  static const numD017 = 0.017;
  static const numD018 = 0.018;
  static const numD019 = 0.019;
  static const numD02 = 0.02;
  static const numD021 = 0.021;
  static const numD022 = 0.022;
  static const numD023 = 0.023;
  static const numD024 = 0.024;
  static const numD025 = 0.025;
  static const numD026 = 0.026;
  static const numD027 = 0.027;
  static const numD028 = 0.028;
  static const numD029 = 0.029;
  static const numD03 = 0.03;
  static const numD031 = 0.031;
  static const numD032 = 0.032;
  static const numD033 = 0.033;
  static const numD034 = 0.034;
  static const numD035 = 0.035;
  static const numD036 = 0.036;
  static const numD037 = 0.037;
  static const numD0375 = 0.0375;
  static const numD038 = 0.038;
  static const numD039 = 0.039;
  static const numD04 = 0.04;
  static const numD040 = 0.040;
  static const numD041 = 0.041;
  static const numD042 = 0.042;
  static const numD043 = 0.043;
  static const numD044 = 0.044;
  static const numD045 = 0.045;
  static const numD046 = 0.046;
  static const numD047 = 0.047;
  static const numD048 = 0.048;
  static const numD049 = 0.049;
  static const numD05 = 0.05;
  static const numD051 = 0.0511;
  static const numD052 = 0.052;
  static const numD053 = 0.053;
  static const numD054 = 0.054;
  static const numD055 = 0.055;
  static const numD056 = 0.056;
  static const numD0565 = 0.0565;
  static const numD0568 = 0.0568;
  static const numD057 = 0.057;
  static const numD0575 = 0.0575;
  static const numD058 = 0.058;
  static const numD0585 = 0.0585;
  static const numD059 = 0.059;
  static const numD06 = 0.06;
  static const numD065 = 0.065;
  static const numD07 = 0.07;
  static const numD072 = 0.072;
  static const numD075 = 0.075;
  static const numD08 = 0.08;
  static const numD081 = 0.081;
  static const numD082 = 0.082;
  static const numD083 = 0.083;
  static const numD084 = 0.084;
  static const numD085 = 0.085;
  static const numD09 = 0.09;
  static const numD10 = 0.10;
  static const numD095 = 0.095;
  static const numD1 = 0.1;
  static const numD11 = 0.11;
  static const numD12 = 0.12;
  static const numD13 = 0.13;
  static const numD14 = 0.14;
  static const numD15 = 0.15;
  static const numD16 = 0.16;
  static const numD17 = 0.17;
  static const numD18 = 0.18;
  static const numD19 = 0.19;
  static const numD20 = 0.20;
  static const numD21 = 0.21;
  static const numD22 = 0.22;
  static const numD23 = 0.23;
  static const numD24 = 0.24;
  static const numD25 = 0.25;
  static const numD26 = 0.26;
  static const numD27 = 0.27;
  static const numD28 = 0.28;
  static const numD29 = 0.29;
  static const numD30 = 0.30;
  static const numD31 = 0.31;
  static const numD32 = 0.32;
  static const numD33 = 0.33;
  static const numD34 = 0.34;
  static const numD35 = 0.35;
  static const numD36 = 0.36;
  static const numD37 = 0.37;
  static const numD38 = 0.38;
  static const numD39 = 0.39;
  static const numD40 = 0.40;
  static const numD44 = 0.44;
  static const numD45 = 0.45;
  static const numD47 = 0.47;
  static const numD48 = 0.48;
  static const numD50 = 0.50;
  static const numD51 = 0.51;
  static const numD52 = 0.52;
  static const numD53 = 0.53;
  static const numD54 = 0.54;
  static const numD55 = 0.55;
  static const numD60 = 0.60;
  static const numD65 = 0.65;
  static const numD70 = 0.70;
  static const numD80 = 0.80;
  static const numD90 = 0.90;

  // ── Raw Double Constants ──
  // Typically used for paddings, sizes, flex values, aspect ratios
  static const num0 = 0.0;
  static const num1 = 1.0;
  static const num15 = 1.5;
  static const num16 = 1.6;
  static const num17 = 1.7;
  static const num18 = 1.8;
  static const num19 = 1.9;
  static const num2 = 2.0;
  static const num21 = 2.1;
  static const num22 = 2.2;
  static const num225 = 2.25;
  static const num23 = 2.3;
  static const num24 = 2.4;
  static const num25 = 2.5;
  static const num26 = 2.6;
  static const num27 = 2.7;
  static const num28 = 2.8;
  static const num29 = 2.9;
  static const num3 = 3.0;
  static const num31 = 3.1;
  static const num32 = 3.2;
  static const num33 = 3.3;
  static const num34 = 3.4;
  static const num35 = 3.5;
  static const num36 = 3.6;
  static const num37 = 3.7;
  static const num4 = 4.0;
  static const num5 = 5.0;
  static const num51 = 5.1;
  static const num52 = 5.2;
  static const num53 = 5.3;
  static const num54 = 5.4;
  static const num55 = 5.5;
  static const num56 = 5.6;
  static const num57 = 5.7;
  static const num58 = 5.8;
  static const num59 = 5.9;
  static const num6 = 6.0;
  static const num7 = 7.0;
  static const num8 = 8.0;
  static const num9 = 9.0;
  static const num10 = 10.0;

  // ── Raw Integer Constants ──
  // Typically used for loops, items counts, static flags
  static const numInt0 = 0;
  static const numInt1 = 1;
  static const numInt2 = 2;
  static const numInt3 = 3;
  static const numInt4 = 4;
  static const numInt5 = 5;
  static const numInt6 = 6;
  static const numInt7 = 7;
  static const numInt8 = 8;
  static const numInt9 = 9;
  static const numInt10 = 10;

  // ── Layout & Font Sizing Helpers ──
  static const headerFontSize = 0.06;
  static const appBarHeadingFontSize = 0.045;
  static const appBarHeadingFontSizeNew = 0.05;
  static double commonPaddingSize(Size size) => size.width * numD04;
}

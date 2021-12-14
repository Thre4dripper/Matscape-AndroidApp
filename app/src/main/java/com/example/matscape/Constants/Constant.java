package com.example.matscape.Constants;

public class Constant {
    //Expression Build Time Error Codes
    public static final int ERROR_EMPTY_BRACKETS=-11;
    public static final int ERROR_MISTAKE_BRACKETS=-12;
    public static final int ERROR_MISTAKE_OPERATOR=-2;
    public static final int ERROR_MISTAKE_MATRIX=-3;
    public static final int ERROR_MISTAKE_DECIMAL=-4;
    public static final int ERROR_MISTAKE_TRANSPOSE=-5;

    //Evaluation Time Error Codes
    public static final int ERROR_SCALAR_TRANSPOSE=-10;
    public static final int ERROR_MATRIX_SCALAR_ADDITION=-20;
    public static final int ERROR_MATRIX_SCALAR_SUBTRACTION=-30;
    public static final int ERROR_SQUARE_MATRIX_POWER=-130;
    public static final int ERROR_INCOMPATIBLE_DIMENS=-40;
    public static final int ERROR_SQUARE_MATRIX_DETERMINANT=-60;
    public static final int ERROR_SQUARE_MATRIX_TRACE=-70;
    public static final int ERROR_SQUARE_MATRIX_ADJOINT=-80;
    public static final int ERROR_SQUARE_MATRIX_MINORS=-100;
    public static final int ERROR_SQUARE_MATRIX_COFACTORS=-120;
    public static final int ERROR_SINGULAR_MATRIX_INVERSE=-140;
    public static final int ERROR_1X1_MINOR=-90;
    public static final int ERROR_1X1_COFACTOR=-110;
    public static final int ERROR_MATRIX_DIVIDE_SINGULAR=-50;
    public static final int ERROR_NO_MATRIX_FOUND=-150;

    //Evaluation Time Warnings
    public static final int WARNING_DIVISOR_AS_INVERSE=50;
    public static final int WARNING_1X1_DETERMINANT=60;

    //String Constants
    public static final String DET="det";
    public static final String TRC="trc";
    public static final String ADJ="adj";
    public static final String MIN="min";
    public static final String COF="cof";

    public static final String DET_SYMBOL="#";
    public static final String TRC_SYMBOL="$";
    public static final String ADJ_SYMBOL="@";
    public static final String MIN_SYMBOL="%";
    public static final String COF_SYMBOL="&";
    public static final String MAT_UNARY_MINUS="~";


}

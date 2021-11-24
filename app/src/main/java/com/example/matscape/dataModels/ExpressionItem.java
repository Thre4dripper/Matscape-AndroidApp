package com.example.matscape.dataModels;

public class ExpressionItem {

    String text;
    int type;
    int resultCardIndex;

    public ExpressionItem(String text, int type,int resultCardIndex) {
        this.text = text;
        this.type = type;
        this.resultCardIndex=resultCardIndex;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public int getResultCardIndex() {
        return resultCardIndex;
    }

    public void setResultCardIndex(int resultCardIndex) {
        this.resultCardIndex = resultCardIndex;
    }
}

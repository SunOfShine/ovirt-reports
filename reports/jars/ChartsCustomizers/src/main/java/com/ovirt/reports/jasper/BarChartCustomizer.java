package com.ovirt.reports.jasper;

import java.awt.Shape;
import java.awt.geom.Rectangle2D;
import java.text.DecimalFormat;

import net.sf.jasperreports.engine.JRChart;
import net.sf.jasperreports.engine.JRChartCustomizer;

import org.jfree.chart.JFreeChart;
import org.jfree.chart.LegendItem;
import org.jfree.chart.LegendItemCollection;
import org.jfree.chart.axis.AxisLocation;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.block.BlockBorder;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.renderer.category.BarRenderer;

public class BarChartCustomizer implements JRChartCustomizer {
	public void customize(JFreeChart chart, JRChart jasperChart) {
		BarRenderer renderer = (BarRenderer) chart.getCategoryPlot().getRenderer();
		CategoryPlot categoryPlot = renderer.getPlot();
		renderer.setBaseItemLabelsVisible(false);
		
		categoryPlot.setNoDataMessage("No Data Available");
		categoryPlot.setRangeAxisLocation(AxisLocation.BOTTOM_OR_LEFT);
		
		
//		Widen the categories so those dots won't show up in the category.
		CategoryAxis domainaxis = categoryPlot.getDomainAxis();
        domainaxis.setMaximumCategoryLabelWidthRatio(1.5f); 
        domainaxis.setTickMarksVisible(true);
        
        
        LegendItemCollection chartLegend = categoryPlot.getLegendItems();
        LegendItemCollection res = new LegendItemCollection();
        Shape square = new Rectangle2D.Double(0,0,5,5);
        for (int i = 0; i < chartLegend.getItemCount(); i++) {
           LegendItem item = chartLegend.get(i);
           String label = item.getLabel();
           if (label.length() > 18)
           {
        	   label = label.substring(0,10).concat("...").concat(label.substring(label.length() - 5, label.length()));
           }
           if (label.trim() != "" && item.getDescription().trim() != "")
           {
           res.add(new LegendItem(label, item.getDescription(), item.getToolTipText(), item.getURLText(), true, square, true, item.getFillPaint(), item.isShapeOutlineVisible(), item.getOutlinePaint(), item.getOutlineStroke(), false, item.getLine(), item.getLineStroke(), item.getLinePaint()));
           }
        }
        categoryPlot.setFixedLegendItems(res);
        chart.getLegend().setFrame(BlockBorder.NONE);
        
		ValueAxis rangeAxis = categoryPlot.getRangeAxis();
		if (rangeAxis instanceof NumberAxis) { 
			NumberAxis axis = (NumberAxis) rangeAxis;
			axis.setNumberFormatOverride(new DecimalFormat("###,###,###.#"));
			axis.setUpperBound(axis.getUpperBound()+1);
			axis.setAutoRangeMinimumSize(1.0);
		}
	}
}

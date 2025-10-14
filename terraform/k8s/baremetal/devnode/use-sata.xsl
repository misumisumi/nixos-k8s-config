<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/domain/devices">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
        <xsl:element name ="disk">
          <xsl:attribute name="type">file</xsl:attribute>
          <xsl:attribute name="device">cdrom</xsl:attribute>
          <xsl:element name="driver">
            <xsl:attribute name="name">qemu</xsl:attribute>
            <xsl:attribute name="type">raw</xsl:attribute>
          </xsl:element>
          <xsl:element name="source">
              <xsl:attribute name="file">/home/sumi/Templates/nix/nixos-k8s-config/result/iso/nixos-23.11.20240502.383ffe0-x86_64-linux.iso</xsl:attribute>
          </xsl:element>
          <xsl:element name="target">
            <xsl:attribute name="dev">sdz</xsl:attribute>
            <xsl:attribute name="bus">sata</xsl:attribute>
          </xsl:element>
          <xsl:element name="address">
            <xsl:attribute name="type">drive</xsl:attribute>
            <xsl:attribute name="controller">0</xsl:attribute>
            <xsl:attribute name="bus">0</xsl:attribute>
            <xsl:attribute name="target">0</xsl:attribute>
            <xsl:attribute name="unit">4</xsl:attribute>
          </xsl:element>
        </xsl:element>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/domain/devices/disk[@device='disk']/target/@bus">
    <xsl:attribute name="bus">sata</xsl:attribute>
  </xsl:template>


</xsl:stylesheet>

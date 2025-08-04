/*  
Exec Zrit_eWaybill_ByIRN_getData 7, 'CI2412260000234', 'RM_SI',''  
Exec Zrit_eWaybill_getData 122, 'CPS450124000001', 'SAL_PS',''     
Exec Zrit_eWaybill_getData 47, 'CI2713260000027', 'RM_SI',''     
Exec Zrit_eWaybill_getData 45, 'MHP/PKS23/000080','SAL_PS', ''  
Exec Zrit_eWaybill_getData 9, 'AT2646260000002','FA_AIFBTR', ''         

*/  
Create or alter  Proc Zrit_eWaybill_getData   
(  
 @Ou   Int,  
 @TranNo  VarChar(20),  
 @TranType VarChar(20),  
 @Process VarChar(20)   
)  
As  
Begin   

Declare @orderno varchar(100)
declare @limit_value numeric(28,8),@intr_intra varchar(100),@tax_cat varchar(50)

if @TranType in('SAL_PS','RM_SI')
begin


if @TranType in('RM_SI')
begin

select @orderno= so_no
from  scmdb..cobi_item_dtl (Nolock)
where tran_no=@TranNo
and   tran_ou	  =@Ou

end 
select @orderno= psd_ordernumber
from  scmdb..ps_pack_slip_dtl (Nolock)
where psd_pkslipno=@TranNo
and   psd_ou	  =@Ou


if isnull(@orderno,'')<>''
begin


 select @tax_cat = tax_category
 from scmdb..tcal_tax_hdr with(Nolock)
 where tran_type='SAL_NSO'
 and tax_type='GST'
 and tran_no=@orderno
 and tran_ou=@Ou

 
 end

end

else if @TranType='SAL_STN'
begin

 select @tax_cat = tax_category
 from scmdb..tcal_tax_hdr with(Nolock)
 where tran_type='SAL_STN'
 and tax_type='GST'
 and tran_no=@tranno
 and tran_ou=@Ou

end



 if @tax_cat like '%local%'
 begin
 select @intr_intra=1
 end
 else if @tax_cat like '%inter%'
 begin
 select @intr_intra=2
 end

 select @limit_value=Limit_Value
 from Zrit_ZEWAYBILL_CONFIG
 join zrit_ids_ou_vw
 on ouid=plant
 where ouinstid=@ou
 and intra_intr=@intr_intra

 select @limit_value=ISNULL(@limit_value,0)



if exists(
select '*' from scmdb..tcal_tax_hdr(nolock) where tran_no=@tranno
and tax_type='GST'
and own_regd_no=party_regd_no
and tax_incl_amt>=@limit_value
and ref_doc_no not like 'TRD%'
)  and @TranType = 'RM_SI' 
 Begin   
  --HEADER DETAILS   
  SELECT distinct
  CobiHdr.tran_ou      As Ou,     
    CobiHdr.tran_no      As TranNo,    
    CobiHdr.tran_type     As TranType,   
      
    CobiHdr.tran_no      As DocumentNumber,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then 'CHL'  
     Else 'INV' End     As DocumentType,   
    Convert(VarChar(10),  
     CobiHdr.tran_date,103)   As DocumentDate,  
    'Outward'       As SupplyType,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then '5'  
     Else '1' End     As SubSupplyType,  
    ''         As SubSupplyTypeDesc,  
 /* Case When Sell.TAX_REGION =    
     CustMst2.Stcd Then '1'  
      Else '2' End    As TransactionType, */
	   case when Sell.Pin=OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 1 
	  when Sell.Pin=OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 2
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 3
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 4
	  else 1 end  As TransactionType,
      --1 or Regular  
      --2 or Bill to-ship to  
      --3 or Bill from-dispatch from  
      --4 or Combination  
    --CobiHdr.tran_amount     As TotalInvoiceAmount,   
	tax.totalamount    as TotalInvoiceAmount,
    Tax.CGST       As TotalCgstAmount,  
    Tax.SGST       As TotalSgstAmount,  
    Tax.IGST       As TotalIgstAmount,  
    0.00        As TotalCessAmount,  
    0.00        As TotalCessNonAdvolAmount,  
    Tax.taxable_amt      As TotalAssessableAmount,  
    Tax.OtherCharge      As OtherAmount,  
    Tax.TCS              As OtherTcsAmount,   
    Null        As TransId,  
    Car.car_carrier_name     As TransName,  
    Case When Pkslp.psh_shipmentmode = 'ROAD'   
     Then 1 Else 2 End /*RAIL*/   As TransMode,      
    --0         As Distance,   
	Distance     As Distance,
    Replace(CobiHdr.tran_no,'/','')  As TransDocNo,  
    Convert(VarChar(10),  
    CobiHdr.tran_date,103)    As TransDocDt,  
  
    Case When Pkslp.psh_shipmentmode = 'ROAD'  
     Then Pkslp.psh_vehicleno       
     Else Null End     As VehNo,   
    Case When Pkslp.psh_shipmentmode = 'ROAD'  
     Then 'REGULAR'  
     Else Null End     As VehType,  
  
      
    CustMst1.Cust_GSTN     As BuyerDtls_Gstin,  
    CustMst1.Cust_Name     As BuyerDtls_LglNm,  
    CustMst1.Cust_Name     As BuyerDtls_TrdNm,  
    CustMst1.Addr1      As BuyerDtls_Addr1,  
    CustMst1.Addr2      As BuyerDtls_Addr2,  
    CustMst1.Loc      As BuyerDtls_Loc,  
    CustMst1.Pin      As BuyerDtls_Pin,  
    CustMst1.Stcd      As BuyerDtls_Stcd,   
       
    Tax.own_regd_no      As SellerDtls_Gstin,  
    OuDet.company_name     As SellerDtls_LglNm,  
    OuDet.company_name     As SellerDtls_TrdNm,     
    Sell.Addr1       As SellerDtls_Addr1,  
    Sell.Addr2       As SellerDtls_Addr2,  
    Sell.Loc       As SellerDtls_Loc,  
    Sell.Pin       As SellerDtls_Pin,  
    Sell.TAX_REGION      As SellerDtls_Stcd,  
      
    CustMst2.Cust_Name     As ExpShipDtls_LglNm,   
    CustMst2.Addr1      As ExpShipDtls_Addr1,  
    CustMst2.Addr2      As ExpShipDtls_Addr2,  
    CustMst2.Loc      As ExpShipDtls_Loc,  
    CustMst2.Pin      As ExpShipDtls_Pin,  
    CustMst2.Stcd      As ExpShipDtls_Stcd,  
  
    OuDet.company_name     As DispDtls_Nm,  
    OuDet.Addr1       As DispDtls_Addr1,  
    OuDet.Addr2       As DispDtls_Addr2,  
    OuDet.Loc  As DispDtls_Loc,  
    OuDet.Pin       As DispDtls_Pin,  
    Sell.TAX_REGION      As DispDtls_Stcd   
  FROM scmdb..cobi_invoice_hdr  CobiHdr (Nolock)  
  Join scmdb..cobi_item_dtl  CobiDtl (Nolock)  
  On  CobiHdr.tran_no     =    CobiDtl.tran_no    
  And  CobiHdr.tran_ou     =    CobiDtl.tran_ou     
  And  CobiHdr.tran_no    =    @TranNo  
  And  CobiHdr.tran_ou     =    @Ou 
  And  CobiHdr.tran_status    =    'AUT'     
  Join SCMDB..ps_pack_slip_hdr    Pkslp (NOLOCK)      
  On  CobiDtl.ref_doc_no    =    Pkslp.psh_pkslipno     
  And  CobiDtl.ref_doc_ou    =    Pkslp.psh_ou    
  Join SCMDB..car_carrier_lo_hdr   Car (Nolock)    
  On  Pkslp.psh_carriercode   =    Car.car_carrier_code    
  Join (select sum(taxable_amt) taxable_amt,sum(CGST) CGST,sum(IGST) IGST,sum(SGST) SGST,
  sum(OtherCharge) OtherCharge,sum(TCS) TCS,sum(totalamount)totalamount ,tran_no,tran_ou,own_regd_no
  from Zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)               
  group by tran_no,tran_ou,own_regd_no
  ) tax
  On  CobiHdr.tran_no      =    Tax.tran_no            
  And  CobiHdr.tran_ou     =    Tax.tran_ou   
  --zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  --On  CobiHdr.tran_no      =    Tax.tran_no    
  --And  CobiHdr.tran_ou     =    Tax.tran_ou 
  --and  tax.tran_line_no        =    CobiDtl.so_line_no
  Join zrit_rmcl_eInvoice_SellerDtls Sell (Nolock)   
  On  own_regd_no      =    Sell.Regd_No     
  and  CobiHdr.tran_ou  = sell.Ou---code added By Paul on 24-03-2024
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst1  (Nolock)      
  On  CobiHdr.bill_to_cust   =   CustMst1.Cust_Code     
  And  CustMst1.isBillTo    =   'Y'   
  Join zrit_rmcl_eInvoice_OuAddress  OuDet (Nolock)     
  On  CobiHdr.tran_ou     =   OuDet.OUInstId    
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst2  (Nolock)      
  On  CobiHdr.bill_to_cust   =   CustMst2.Cust_Code     
  And  CobiDtl.ship_to_id    =   CustMst2.AddressId   
  and TotalAmount>=@limit_value
  and CobiDtl.so_no not like 'TRD%'  
  
  
  --ITEM DETAILS  
  Select CobiHdr.tran_ou      As Ou,     
    CobiHdr.tran_no      As TranNo,    
    CobiHdr.tran_type     As TranType,    
      
    CobiDtl.item_tcd_code    As ItemList_ProdName,  
    itm_itemdesc      As ItemList_ProdDesc,  
    hsn_code       As ItemList_HsnCd,   
    Tax.quantity      As ItemList_Qty,  
    CobiDtl.uom       As ItemList_Unit,   
    Tax.taxable_amt      As ItemList_AssAmt,   
    Tax.CGSTRate      As ItemList_CgstRt,  
    Tax.CGST        As ItemList_CgstAmt,  
Tax.SGSTRate  As ItemList_SgstRt,  
    Tax.SGST        As ItemList_SgstAmt,  
    Tax.IGSTRate      As ItemList_IgstRt,  
    Tax.IGST        As ItemList_IgstAmt,  
    0.00        As ItemList_CesRt,  
    0.00        As ItemList_CesAmt,  
    Tax.TCS        As ItemList_OthChrg,   
    0.00        As ItemList_CesNonAdvAmt  
  FROM scmdb..cobi_invoice_hdr  CobiHdr (Nolock)  
  Join scmdb..cobi_item_dtl  CobiDtl (Nolock)  
  On  CobiHdr.tran_no     =    CobiDtl.tran_no    
  And  CobiHdr.tran_ou     =    CobiDtl.tran_ou     
  And  CobiHdr.tran_no     =    @TranNo  
  And  CobiHdr.tran_ou     =    @Ou  
  And  CobiHdr.tran_status    =    'AUT'    
  Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  On  CobiHdr.tran_no      =    Tax.tran_no    
  And  CobiHdr.tran_ou     =    Tax.tran_ou 
  and  tax.tran_line_no        =    CobiDtl.so_line_no
  Join zrit_rmcl_eInvoice_Itm_Master Itm   (Nolock)     
  On  CobiDtl.item_tcd_code   =   Itm.itm_itemcode     
  And  CobiDtl.item_tcd_var   =   Itm.itm_variantcode   
  And  Itm.itemType     =   'FP'   
  and TotalAmount>=@limit_value
  and CobiDtl.so_no not like 'TRD%'  
 return  
 End   


 
 ---------------  
 --COBI  
 ---------------  
 If @TranType = 'RM_SI'  
 Begin   
  --HEADER DETAILS   
  SELECT distinct
  CobiHdr.tran_ou      As Ou,     
    CobiHdr.tran_no      As TranNo,    
    CobiHdr.tran_type     As TranType,   
      
    CobiHdr.tran_no      As DocumentNumber,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then 'CHL'  
     Else 'INV' End     As DocumentType,   
    Convert(VarChar(10),  
     CobiHdr.tran_date,103)   As DocumentDate,  
    'Outward'       As SupplyType,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then '5'  
     Else '1' End     As SubSupplyType,  
    ''         As SubSupplyTypeDesc,  
 /* Case When Sell.TAX_REGION =    
     CustMst2.Stcd Then '1'  
      Else '2' End    As TransactionType, */
	   case when Sell.Pin=OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 1 
	  when Sell.Pin=OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 2
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 3
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 4
	  else 1 end  As TransactionType,
      --1 or Regular  
      --2 or Bill to-ship to  
      --3 or Bill from-dispatch from  
      --4 or Combination  
    --CobiHdr.tran_amount     As TotalInvoiceAmount,   
	tax.totalamount    as totalamount,
    Tax.CGST       As TotalCgstAmount,  
    Tax.SGST       As TotalSgstAmount,  
    Tax.IGST       As TotalIgstAmount,  
    0.00        As TotalCessAmount,  
    0.00        As TotalCessNonAdvolAmount,  
    Tax.taxable_amt      As TotalAssessableAmount,  
    Tax.OtherCharge      As OtherAmount,  
    Tax.TCS              As OtherTcsAmount,   
    Null        As TransId,  
    Car.car_carrier_name     As TransName,  
    Case When Pkslp.psh_shipmentmode = 'ROAD'   
     Then 1 Else 2 End /*RAIL*/   As TransMode,      
    --0         As Distance,   
	Distance     As Distance,
    Replace(CobiHdr.tran_no,'/','')  As TransDocNo,  
    Convert(VarChar(10),  
    CobiHdr.tran_date,103)    As TransDocDt,  
  
    Case When Pkslp.psh_shipmentmode = 'ROAD'  
     Then Pkslp.psh_vehicleno       
     Else Null End     As VehNo,   
    Case When Pkslp.psh_shipmentmode = 'ROAD'  
     Then 'REGULAR'  
     Else Null End     As VehType,  
  
      
    CustMst1.Cust_GSTN     As BuyerDtls_Gstin,  
    CustMst1.Cust_Name     As BuyerDtls_LglNm,  
    CustMst1.Cust_Name     As BuyerDtls_TrdNm,  
    CustMst1.Addr1      As BuyerDtls_Addr1,  
    CustMst1.Addr2      As BuyerDtls_Addr2,  
    CustMst1.Loc      As BuyerDtls_Loc,  
    CustMst1.Pin      As BuyerDtls_Pin,  
    CustMst1.Stcd      As BuyerDtls_Stcd,   
       
    Tax.own_regd_no      As SellerDtls_Gstin,  
    OuDet.company_name     As SellerDtls_LglNm,  
 OuDet.company_name    As SellerDtls_TrdNm,     
    Sell.Addr1       As SellerDtls_Addr1,  
    Sell.Addr2    As SellerDtls_Addr2,  
    Sell.Loc       As SellerDtls_Loc,  
    Sell.Pin       As SellerDtls_Pin,  
    Sell.TAX_REGION      As SellerDtls_Stcd,  
      
    CustMst2.Cust_Name     As ExpShipDtls_LglNm,   
    CustMst2.Addr1      As ExpShipDtls_Addr1,  
    CustMst2.Addr2      As ExpShipDtls_Addr2,  
    CustMst2.Loc      As ExpShipDtls_Loc,  
    CustMst2.Pin      As ExpShipDtls_Pin,  
    CustMst2.Stcd      As ExpShipDtls_Stcd,  
  
    OuDet.company_name     As DispDtls_Nm,  
    OuDet.Addr1       As DispDtls_Addr1,  
    OuDet.Addr2       As DispDtls_Addr2,  
    OuDet.Loc  As DispDtls_Loc,  
    OuDet.Pin       As DispDtls_Pin,  
    Sell.TAX_REGION      As DispDtls_Stcd   
  FROM scmdb..cobi_invoice_hdr  CobiHdr (Nolock)  
  Join scmdb..cobi_item_dtl  CobiDtl (Nolock)  
  On  CobiHdr.tran_no     =    CobiDtl.tran_no    
  And  CobiHdr.tran_ou     =    CobiDtl.tran_ou     
  And  CobiHdr.tran_no    =    @TranNo  
  And  CobiHdr.tran_ou     =    @Ou 
  And  CobiHdr.tran_status    =    'AUT'     
  Join SCMDB..ps_pack_slip_hdr    Pkslp (NOLOCK)      
  On  CobiDtl.ref_doc_no    =    Pkslp.psh_pkslipno     
  And  CobiDtl.ref_doc_ou    =    Pkslp.psh_ou    
  Join SCMDB..car_carrier_lo_hdr   Car (Nolock)    
  On  Pkslp.psh_carriercode   =    Car.car_carrier_code    
  Join (select sum(taxable_amt) taxable_amt,sum(CGST) CGST,sum(IGST) IGST,sum(SGST) SGST,
  sum(OtherCharge) OtherCharge,sum(TCS) TCS,sum(totalamount)totalamount ,tran_no,tran_ou,own_regd_no
  from Zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)               
  group by tran_no,tran_ou,own_regd_no
  ) tax
  On  CobiHdr.tran_no      =    Tax.tran_no            
  And  CobiHdr.tran_ou     =    Tax.tran_ou   
  --zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  --On  CobiHdr.tran_no      =    Tax.tran_no    
  --And  CobiHdr.tran_ou     =    Tax.tran_ou 
  --and  tax.tran_line_no        =    CobiDtl.so_line_no
  Join zrit_rmcl_eInvoice_SellerDtls Sell (Nolock)   
  On  own_regd_no      =    Sell.Regd_No     
  and  CobiHdr.tran_ou  = sell.Ou---code added By Paul on 24-03-2024
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst1  (Nolock)      
  On  CobiHdr.bill_to_cust   =   CustMst1.Cust_Code     
  And  CustMst1.isBillTo    =   'Y'   
  Join zrit_rmcl_eInvoice_OuAddress  OuDet (Nolock)     
  On  CobiHdr.tran_ou     =   OuDet.OUInstId    
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst2  (Nolock)      
  On  CobiHdr.bill_to_cust   =   CustMst2.Cust_Code     
  And  CobiDtl.ship_to_id    =   CustMst2.AddressId   
  and TotalAmount>=@limit_value
  and CobiDtl.so_no not like 'TRD%'    
  
  
  --ITEM DETAILS  
  Select CobiHdr.tran_ou      As Ou,     
    CobiHdr.tran_no      As TranNo,    
    CobiHdr.tran_type     As TranType,    
    CobiDtl.item_tcd_code    As ItemList_ProdName,  
    itm_itemdesc      As ItemList_ProdDesc,  
    hsn_code       As ItemList_HsnCd,   
    Tax.quantity      As ItemList_Qty,  
    CobiDtl.uom       As ItemList_Unit,   
    Tax.taxable_amt      As ItemList_AssAmt,   
    Tax.CGSTRate      As ItemList_CgstRt,  
    Tax.CGST        As ItemList_CgstAmt,  
    Tax.SGSTRate      As ItemList_SgstRt,  
    Tax.SGST        As ItemList_SgstAmt,  
    Tax.IGSTRate      As ItemList_IgstRt,  
    Tax.IGST        As ItemList_IgstAmt,  
    0.00        As ItemList_CesRt,  
    0.00        As ItemList_CesAmt,  
    Tax.TCS        As ItemList_OthChrg,   
    0.00        As ItemList_CesNonAdvAmt  
  FROM scmdb..cobi_invoice_hdr  CobiHdr (Nolock)  
  Join scmdb..cobi_item_dtl  CobiDtl (Nolock)  
  On  CobiHdr.tran_no     =    CobiDtl.tran_no    
  And  CobiHdr.tran_ou     =    CobiDtl.tran_ou     
  And  CobiHdr.tran_no     =    @TranNo  
  And  CobiHdr.tran_ou     =    @Ou  
  And  CobiHdr.tran_status    =    'AUT'    
  Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
On  CobiHdr.tran_no      =    Tax.tran_no    
  And  CobiHdr.tran_ou     =    Tax.tran_ou 
  and  tax.tran_line_no        =    CobiDtl.so_line_no
  Join zrit_rmcl_eInvoice_Itm_Master Itm   (Nolock)     
  On  CobiDtl.item_tcd_code   =   Itm.itm_itemcode     
  And  CobiDtl.item_tcd_var   =   Itm.itm_variantcode   
  And  Itm.itemType     in(   'FP','SC')  
  and TotalAmount>=@limit_value
  and CobiDtl.so_no not like 'TRD%'   
 End   
 Else if @TranType = 'SAL_STN'        
 Begin  --STI  
    
  --HEADER DETAILS    
  SELECT StiHdr.stihdr_ou     As Ou,     
    StiHdr.stihdr_sti_no    As TranNo,    
    @TranType       As TranType,     
      
    StiHdr.stihdr_sti_no    As DocumentNumber,   
    Case When Tax.own_regd_no =   
     Tax.party_regd_no Then 'CHL'  
     Else 'INV' End     As DocumentType,   
    Convert(VarChar(10),  
     StiHdr.stihdr_ship_date,103) As DocumentDate,  
  
     'Outward'      As SupplyType,  
    Case When Tax.own_regd_no =   
     Tax.party_regd_no  Then '5'  
     Else '1' End     As SubSupplyType,  
     ''        As SubSupplyTypeDesc,  
    Case When Left(Tax.own_regd_no,2)= 
     Left(Tax.party_regd_no,2)  
     Then '1' Else '2' End   As TransactionType,  
      --1 or Regular  
      --2 or Bill to-ship to  
      --3 or Bill from-dispatch from  
      --4 or Combination    
    Tax.TotalAmount       As TotalInvoiceAmount,   
    Tax.CGST       As TotalCgstAmount,   
    Tax.CGST       As TotalSgstAmount,   
    Tax.IGST       As TotalIgstAmount,  
    0.00        As TotalCessAmount,   
    0.00        As TotalCessNonAdvolAmount,   
    Tax.taxable_amt      As TotalAssessableAmount,  
    0.00        As OtherAmount,   
    Tax.TCS        As OtherTcsAmount,   
  
    Null         As TransId, 
    Car.car_carrier_name     As TransName,   
    Case When Pkslp.psh_shipmentmode = 'ROAD'   
     Then 1 Else 2 End /*RAIL*/    As TransMode,  
    --0          As Distance,   
	isnull(Distance,0)     As Distance,
    Replace(StiHdr.stihdr_sti_no,'/','') As TransDocNo,   
    Convert(VarChar(10),  
     StiHdr.stihdr_ship_date,103)  As TransDocDt,   
    Case When Pkslp.psh_shipmentmode = 'ROAD'   
     Then Pkslp.psh_vehicleno  
     Else Null End       As VehNo,   
    Case When Pkslp.psh_shipmentmode = 'ROAD'   
     Then 'REGULAR'  
     Else Null End       As VehType,  
      
    Tax.party_regd_no     As BuyerDtls_Gstin,  
    company_name      As BuyerDtls_LglNm,    
    company_name      As BuyerDtls_TrdNm,    
    RecWh.Addr1       As BuyerDtls_Addr1,  
    RecWh.Addr2       As BuyerDtls_Addr2,  
    RecWh.Loc       As BuyerDtls_Loc,  
    RecWh.Pin       As BuyerDtls_Pin,  
    Left(Tax.party_regd_no,2)   As BuyerDtls_Stcd,  
  
    Tax.own_regd_no      As SellerDtls_Gstin,  
    company_name      As SellerDtls_LglNm,  
    company_name      As SellerDtls_TrdNm,     
    Sell.Addr1       As SellerDtls_Addr1,  
    Sell.Addr2       As SellerDtls_Addr2,  
    Sell.Loc       As SellerDtls_Loc,  
    Sell.Pin       As SellerDtls_Pin,  
    Left(Tax.own_regd_no,2)    As SellerDtls_Stcd,   
  
    company_name      As ExpShipDtls_LglNm,  
    RecWh.Addr1       As ExpShipDtls_Addr1,  
    RecWh.Addr2       As ExpShipDtls_Addr2,  
    RecWh.Loc       As ExpShipDtls_Loc,  
    RecWh.Pin       As ExpShipDtls_Pin,  
    Left(Tax.party_regd_no,2)   As ExpShipDtls_Stcd,    
  
    company_name      As DispDtls_Nm,  
    SendWh.Addr1      As DispDtls_Addr1,  
    SendWh.Addr2      As DispDtls_Addr2,  
    SendWh.Loc       As DispDtls_Loc,  
    SendWh.Pin       As DispDtls_Pin,  
    Left(Tax.own_regd_no,2)    As DispDtls_Stcd  
  FROM scmdb..sti_note_hdr      StiHdr (Nolock)  
  Join scmdb..sti_note_item_dtl    StiDtl (Nolock)  
  On  StiHdr.stihdr_sti_no   =   StiDtl.stidtl_sti_no    
  And  StiHdr.stihdr_ou    =   StiDtl.stidtl_ou     
  And  StiHdr.stihdr_sti_no   =   @TranNo  
  And  StiHdr.stihdr_ou  =   @Ou  
  And  StiHdr.stihdr_status   In   ('AU','CL')    
  Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  On  StiHdr.stihdr_sti_no     =  Tax.tran_no    
  And  StiHdr.stihdr_ou    =   Tax.tran_ou  
  and  tax.tran_line_no        =    StiDtl.stidtl_order_line_no
  Join zrit_rmcl_eInvoice_SellerDtls    Sell (Nolock)   
  On  Tax.own_regd_no     =   Sell.Regd_No  
  and  StiHdr.stihdr_ou   = sell.Ou---code added By Paul on 24-03-2024
  Join SCMDB..ps_pack_slip_hdr     Pkslp (NOLOCK)      
  On  StiHdr.stihdr_packslip_no  =   Pkslp.psh_pkslipno   
  And  StiHdr.stihdr_packslip_ou  =    Pkslp.psh_ou     
  Join SCMDB..ps_pack_slip_dtl     PkslpD (Nolock)    
  On  Pkslp.psh_pkslipno    =   PkslpD.psd_pkslipno     
  And  Pkslp.psh_ou     =   PkslpD.psd_ou    
     
  And  PkslpD.psd_pksliplineno   =   1  
  Join scmdb..sto_order_hdr     OrdHdr (Nolock)  
  On  PkslpD.psd_ordernumber   =   OrdHdr.stohdr_order_no   
  --Join SCMDB..sto_order_frt_dtl    Ord  (Nolock)     
  --On  PkslpD.psd_ordernumber   =   Ord.frd_ordernumber    
  --And  PkslpD.psd_orderlineno   =   Ord.frd_orderlineno      
  Join SCMDB..car_carrier_lo_hdr    Car (Nolock)    
  On  Pkslp.psh_carriercode   =   Car.car_carrier_code    
  Join zrit_rmcl_eInvoice_WhAddress     RecWh  (Nolock)     
  On  StiDtl.stidtl_receiving_wh  =   RecWh.Wm_Wh_code    
  Join zrit_rmcl_eInvoice_WhAddress     SendWh  (Nolock)     
  On  StiDtl.stidtl_shipping_wh  =   SendWh.Wm_Wh_code    
  Join zrit_rmcl_eInvoice_OuAddress  OuDet (Nolock)     
  On  StiHdr.stihdr_ou    =   OuDet.OUInstId    
   
   
  --ITEM DETAILS   
  Select StiHdr.stihdr_ou     As Ou,    
    StiHdr.stihdr_sti_no    As TranNo,    
    @TranType       As TranType,   
  
    StiDtl.stidtl_item_code    As ItemList_ProdName,  
    itm_itemdesc      As ItemList_ProdDesc,   
    hsn_code       As ItemList_HsnCd,  
    Tax.quantity      As ItemList_Qty,  
    'NOS'        As ItemList_Unit,  
    --StiDtl.stidtl_uom     As ItemList_Unit,  
    Tax.taxable_amt      As ItemList_AssAmt,  
    '0'         As ItemList_CgstRt,  
    --Tax.CGSTRate      As ItemList_CgstRt,  
    Tax.CGST       As ItemList_CgstAmt,      
    --Tax.SGSTRate      As ItemList_SgstRt,   
    '0'         As ItemList_SgstRt,    
    Tax.SGST       As ItemList_SgstAmt,   
    '0'         As ItemList_IgstRt,   
    --Tax.IGSTRate      As ItemList_IgstRt,    
    Tax.IGST       As ItemList_IgstAmt,  
    0.00        As ItemList_CesRt,  
    0.00        As ItemList_CesAmt,  
    0.00        As ItemList_OthChrg,  
    0.00        As ItemList_CesNonAdvAmt  
  FROM scmdb..sti_note_hdr      StiHdr (Nolock)  
  Join scmdb..sti_note_item_dtl    StiDtl (Nolock)  
  On  StiHdr.stihdr_sti_no   =   StiDtl.stidtl_sti_no    
  And  StiHdr.stihdr_ou    =   StiDtl.stidtl_ou     
  And  StiHdr.stihdr_sti_no   =   @TranNo  
  And  StiHdr.stihdr_ou    =   @Ou  
  And  StiHdr.stihdr_status   In   ('AU','CL')    
  Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  On  StiHdr.stihdr_sti_no     =   Tax.tran_no    
  And  StiHdr.stihdr_ou    =   Tax.tran_ou   
  and  tax.tran_line_no        =    StiDtl.stidtl_order_line_no
  Join zrit_rmcl_eInvoice_Itm_Master    Itm   (Nolock)     
  On  StiDtl.stidtl_item_code   =   Itm.itm_itemcode     
  And  StiDtl.stidtl_item_variant  =   Itm.itm_variantcode   
  And  Itm.itemType     <>  'FP'    ---code added by nambirajan Discuessed with subramani  
  
    
 End   
 else If @TranType = 'SAL_PS'        
 Begin         


  --HEADER DETAILS         
 SELECT distinct h.psh_ou      As Ou,     
    replace(h.psh_pkslipno,'-','')      As TranNo,    
    @TranType     As TranType,   
      
    replace(h.psh_pkslipno,'-','')      As DocumentNumber,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then 'CHL'  
     Else 'INV' End     As DocumentType,   
    Convert(VarChar(10),  
     h.psh_pkslipdate,103)  As DocumentDate,  
    'Outward'       As SupplyType,  
    Case When Tax.own_regd_no =   
     CustMst2.Cust_GSTN Then '5'  
     Else '1' End     As SubSupplyType,  
    ''         As SubSupplyTypeDesc,  
    /*Case When Sell.TAX_REGION =    
     CustMst2.Stcd Then '1'  
      Else '2' End    As TransactionType,  */--commented  By paul 2024-03-27 
	  case when Sell.Pin=OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 1 
	  when Sell.Pin=OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 2
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin=CustMst2.Pin then 3
	  when Sell.Pin<>OuDet.Pin and CustMst1.Pin<>CustMst2.Pin then 4
	  else 1 end  As TransactionType,
      --1 or Regular  
      --2 or Bill to-ship to  
      --3 or Bill from-dispatch from  
      --4 or Combination  
    sqty.psd_saleuom_pkslipqty * (isnull(taxable_amt,0)/nullif(quantity,0))+--isnull(so.sodtl_sales_price, 0.00)+
	sqty.psd_saleuom_pkslipqty *(isnull(Tax.CGST,0)/nullif(quantity,0)) +
	sqty.psd_saleuom_pkslipqty *(isnull(Tax.SGST,0)/nullif(quantity,0)) +
	sqty.psd_saleuom_pkslipqty *(isnull(Tax.IGST,0)/nullif(quantity,0)) As TotalInvoiceAmount,   

    sqty.psd_saleuom_pkslipqty *(isnull(Tax.CGST,0)/nullif(quantity,0))       As TotalCgstAmount,  
    sqty.psd_saleuom_pkslipqty *(isnull(Tax.SGST,0)/nullif(quantity,0))       As TotalSgstAmount,  
    sqty.psd_saleuom_pkslipqty *(isnull(Tax.IGST,0)/nullif(quantity,0))       As TotalIgstAmount,  
    0.00        As TotalCessAmount,  
    0.00        As TotalCessNonAdvolAmount,  
    sqty.psd_saleuom_pkslipqty*(isnull(Tax.taxable_amt,0)/nullif(quantity,0)  )    As TotalAssessableAmount,  
    sqty.psd_saleuom_pkslipqty*(isnull(Tax.OtherCharge,0)/nullif(quantity,0))      As OtherAmount,  
    sqty.psd_saleuom_pkslipqty*(isnull(Tax.TCS ,0)/nullif(quantity,0))        As OtherTcsAmount,   
    Null        As TransId,  
    Car.car_carrier_name     As TransName,  
    Case When h.psh_shipmentmode = 'ROAD'   
     Then 1 Else 2 End /*RAIL*/   As TransMode,      
    0         As Distance,   
    Replace(h.psh_pkslipno,'/','')  As TransDocNo,  
    Convert(VarChar(10),  
    h.psh_pkslipdate,103)    As TransDocDt,  
  
    Case When h.psh_shipmentmode = 'ROAD'  
     Then h.psh_vehicleno       
     Else Null End  As VehNo,   
    Case When h.psh_shipmentmode = 'ROAD'  
     Then 'REGULAR'     
     Else Null End     As VehType,  
  
      
   CustMst1.Cust_GSTN     As BuyerDtls_Gstin,  
    CustMst1.Cust_Name     As BuyerDtls_LglNm,  
    CustMst1.Cust_Name     As BuyerDtls_TrdNm,  
    CustMst1.Addr1      As BuyerDtls_Addr1,  
    CustMst1.Addr2      As BuyerDtls_Addr2,  
    CustMst1.Loc      As BuyerDtls_Loc,  
    CustMst1.Pin      As BuyerDtls_Pin,  
    CustMst1.Stcd      As BuyerDtls_Stcd,   
    --'19AAACP6224A1ZU'     As SellerDtls_Gstin,  
    Tax.own_regd_no      As SellerDtls_Gstin,  
    OuDet.company_name     As SellerDtls_LglNm,  
    OuDet.company_name     As SellerDtls_TrdNm,     
    Sell.Addr1       As SellerDtls_Addr1,  
    Sell.Addr2       As SellerDtls_Addr2,  
    Sell.Loc       As SellerDtls_Loc,  
    Sell.Pin       As SellerDtls_Pin,  
    Sell.TAX_REGION      As SellerDtls_Stcd,
  CustMst2.Cust_Name     As ExpShipDtls_LglNm,   
    CustMst2.Addr1      As ExpShipDtls_Addr1,  
    CustMst2.Addr2      As ExpShipDtls_Addr2,  
    CustMst2.Loc      As ExpShipDtls_Loc,  
    CustMst2.Pin      As ExpShipDtls_Pin,  
    CustMst2.Stcd      As ExpShipDtls_Stcd,  
    OuDet.company_name     As DispDtls_Nm,  
    OuDet.Addr1       As DispDtls_Addr1,  
    OuDet.Addr2       As DispDtls_Addr2,  
    OuDet.Loc       As DispDtls_Loc,  
    OuDet.Pin       As DispDtls_Pin,  
    Sell.TAX_REGION      As DispDtls_Stcd   
	/* code modified By paul on 2024-03-25 starts here */
  FROM  scmdb..ps_pack_slip_hdr h (nolock)           
 inner join  (select sum(psd_saleuom_pkslipqty) psd_saleuom_pkslipqty,psd_pkslipno,psd_ou,psd_ordernumber from scmdb..ps_pack_slip_dtl d (nolock)       
 where psd_pkslipno=@TranNo
 And  psd_ou     =  @Ou   
 group by psd_pkslipno,psd_ou,psd_ordernumber
 ) sqty     
 on sqty.psd_pkslipno = h.psh_pkslipno        
 And  h.psh_pkslipno     =  @TranNo
 And  h.psh_ou     =  @Ou
 and psh_currentstatus not in ('DE','RV')         
 left join scmdb..so_order_hdr SO (nolock)    -- select * from Mis_sales_sale_order_details_vw         
 on so.sohdr_order_no = sqty.psd_ordernumber         
 --and d.psd_itemcode = so.sodtl_item_code        
 --and d.psd_itemvariant = so.sodtl_item_variant  
 --and d.psd_orderlineno = so.sodtl_line_no  
 and sqty.psd_ou = so.sohdr_ou           
  Join SCMDB..car_carrier_lo_hdr   Car (Nolock)    
  On  h.psh_carriercode   =    Car.car_carrier_code    
  Join(select sum(taxable_amt) taxable_amt,sum(CGST) CGST,sum(IGST) IGST,sum(SGST) SGST,
  sum(OtherCharge) OtherCharge,sum(TCS) TCS,sum(totalamount)totalamount,sum(quantity) quantity,tran_no,tran_ou,own_regd_no
  from Zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)  
  group by tran_no,tran_ou,own_regd_no
  ) tax   
 On  so.sohdr_order_no      =    Tax.tran_no          
  And  so.sohdr_ou=    Tax.tran_ou     
  Join zrit_rmcl_eInvoice_SellerDtls Sell (Nolock)   
  On  own_regd_no      =    Sell.Regd_No    
  and  h.psh_ou  = sell.Ou---code added By Paul on 24-03-2024
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst1  (Nolock)      
  On  h.psh_shiptocust   =   CustMst1.Cust_Code           
  And  CustMst1.isBillTo    =   'Y'  
  Join zrit_rmcl_eInvoice_OuAddress  OuDet (Nolock)     
  On  h.psh_ou     =   OuDet.OUInstId          
  Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst2  (Nolock)      
  On  h.psh_shiptocust   =   CustMst2.Cust_Code           
  And  h.psh_shiptoid    =   CustMst2.AddressId  


    

  
  /*
  scmdb..ps_pack_slip_hdr h (nolock)           
 inner join scmdb..ps_pack_slip_dtl d (nolock)       
 on d.psd_pkslipno = h.psh_pkslipno        
 And  h.psh_pkslipno     =  @TranNo        
 And  h.psh_ou     =  @Ou        
 and psh_currentstatus not in ('DE','RV')         
  left join scmdb..so_order_item_dtl SO (nolock)    -- select * from Mis_sales_sale_order_details_vw         
 on so.sodtl_order_no = d.psd_ordernumber         
 and d.psd_itemcode = so.sodtl_item_code        
 and d.psd_itemvariant = so.sodtl_item_variant  
 and d.psd_orderlineno = so.sodtl_line_no  
 and d.psd_ou = so.sodtl_ou           
 Join SCMDB..car_carrier_lo_hdr   Car (Nolock)    
 On  h.psh_carriercode   =    Car.car_carrier_code    
 Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
 On  so.sodtl_order_no      =    Tax.tran_no          
 And  so.sodtl_ou=    Tax.tran_ou     
 and d.psd_orderlineno=tax.tran_line_no
 Join zrit_rmcl_eInvoice_SellerDtls Sell (Nolock)   
 On  own_regd_no      =    Sell.Regd_No    
 and  h.psh_ou  = sell.Ou---code added By Paul on 24-03-2024
 Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst1  (Nolock)      
 On  h.psh_shiptocust   =   CustMst1.Cust_Code           
 And  CustMst1.isBillTo    =   'Y'  
 Join zrit_rmcl_eInvoice_OuAddress  OuDet (Nolock)     
 On  h.psh_ou     =   OuDet.OUInstId          
 Join zrit_rmcl_eInvoice_Cust_Dtls  CustMst2  (Nolock)      
 On  h.psh_shiptocust   =   CustMst2.Cust_Code           
 And  h.psh_shiptoid    =   CustMst2.AddressId         
 join (select sum(psd_saleuom_pkslipqty) psd_saleuom_pkslipqty,psd_pkslipno,psd_ou from scmdb..ps_pack_slip_dtl d (nolock)       
 where psd_pkslipno=@TranNo
 group by psd_pkslipno,psd_ou) sqty
 on d.psd_pkslipno = sqty.psd_pkslipno        
 and d.psd_ou=sqty.psd_ou
    */
  
  
  --ITEM DETAILS  
  Select h.psh_ou      As Ou,     
    replace(h.psh_pkslipno,'-','')      As TranNo,    
    @TranType     As TranType,    
    d.psd_itemcode    As ItemList_ProdName,  
    itm_itemdesc      As ItemList_ProdDesc,  
    hsn_code       As ItemList_HsnCd,   
    --Tax.quantity      As ItemList_Qty,  
	psd_saleuom_pkslipqty As ItemList_Qty,  
    d.psd_saleorder_uom       As ItemList_Unit,   
     d.psd_saleuom_pkslipqty*(isnull(Tax.taxable_amt,0)/nullif(Tax.quantity,0))      As ItemList_AssAmt,   
    Tax.CGSTRate      As ItemList_CgstRt,  
    d.psd_saleuom_pkslipqty*(isnull(Tax.CGST,0)/nullif(Tax.quantity,0))        As ItemList_CgstAmt,  
    Tax.SGSTRate      As ItemList_SgstRt,  
    d.psd_saleuom_pkslipqty*(isnull(Tax.SGST,0)/nullif(Tax.quantity,0))        As ItemList_SgstAmt,  
    Tax.IGSTRate    As ItemList_IgstRt,  
    d.psd_saleuom_pkslipqty*(isnull(Tax.IGST,0)/nullif(Tax.quantity,0))        As ItemList_IgstAmt,  
    0.00        As ItemList_CesRt,  
    0.00        As ItemList_CesAmt,  
    d.psd_saleuom_pkslipqty*(isnull(Tax.TCS ,0)/nullif(quantity,0))         As ItemList_OthChrg,   
    0.00 As ItemList_CesNonAdvAmt  
  FROM  scmdb..ps_pack_slip_hdr h (nolock)           
  inner join scmdb..ps_pack_slip_dtl d (nolock)       
  on d.psd_pkslipno = h.psh_pkslipno        
  And  h.psh_pkslipno     =  @TranNo        
  And  h.psh_ou     =  @Ou        
   and psh_currentstatus not in ('DE','RV')   
   left join scmdb..so_order_item_dtl SO (nolock)    -- select * from Mis_sales_sale_order_details_vw         
 on so.sodtl_order_no = d.psd_ordernumber         
 and d.psd_itemcode = so.sodtl_item_code        
 and d.psd_itemvariant = so.sodtl_item_variant  
 and d.psd_orderlineno = so.sodtl_line_no  
 and d.psd_ou = so.sodtl_ou      
  Join zrit_rmcl_eInvoice_Tax_Dtls     Tax (Nolock)       
  On  so.sodtl_order_no      =    Tax.tran_no     
  And  so.sodtl_ou=    Tax.tran_ou 
  and tran_line_no=psd_orderlineno ----Code Added By Paulesakki on FEB-26
  Join zrit_rmcl_eInvoice_Itm_Master Itm   (Nolock)     
   On  d.psd_itemcode   =   Itm.itm_itemcode           
  And  d.psd_itemvariant   = Itm.itm_variantcode         
 And  Itm.itemType   =   'FP'   
  
 End 

 
  declare @ou_instname nvarchar(50)
  declare @buyer_ou int,
  @veh     nvarchar(50),
  @carrier  nvarchar(50),
  @carrier_name nvarchar(255)


      select @ou_instname=des_location_code from 
    scmdb..tcal_tax_hdr h(nolock) 
 	where  h.tran_type  =	@TranType
    And    h.tran_no    =   @TranNo   
    And    h.tran_ou    =   @Ou  

   select @buyer_ou=ou_id from scmdb..emod_ou_vw
    where ouinstname=@ou_instname
  
 
 If @TranType  in( 'FA_AIFBTR','FA_AINVTO')
  begin

select 	@veh= substring(remarks,0,charindex(',',remarks))
,@carrier=substring(remarks,charindex(',',remarks)+1,len(remarks))
from scmdb..adisp_transfer_dtl ass(NOLOCK)
where   ASS.transfer_number =@TranNo
and ASS.ou_id           =@Ou


select @carrier_name=car_carrier_name 
from SCMDB..car_carrier_lo_hdr  (NOLOCK)
where  car_carrier_code =@carrier

	
	SELECT --distinct /*code commented by krishnan*/
  t.tran_ou      As Ou,     
    t.tran_no      As TranNo,    
    t.tran_type     As TranType,   
      
    t.tran_no      As DocumentNumber,  
    Case When Tax.own_regd_no =   
     buyer.Regd_No Then 'CHL'  
     Else 'INV' End     As DocumentType,   
    Convert(VarChar(10),t.tran_date,103)   As DocumentDate,  
    'OUTWARD'        As SupplyType,  
    Case When Tax.own_regd_no =   
     Tax.party_regd_no Then '5'  
     Else '1' End     As SubSupplyType,  
    ''         As SubSupplyTypeDesc,  
	   case when Sell.Pin=OuDet.Pin and buyer.Pin=buyer.Pin then 1 
	  when Sell.Pin=OuDet.Pin and buyer.Pin<>buyer.Pin then 2
	  when Sell.Pin<>OuDet.Pin and buyer.Pin=buyer.Pin then 3
	  when Sell.Pin<>OuDet.Pin and buyer.Pin<>buyer.Pin then 4
	  else 1 end  As TransactionType,
      --1 or Regular  
      --2 or Bill to-ship to  
      --3 or Bill from-dispatch from  
      --4 or Combination  
    --t.tran_amount     As TotalInvoiceAmount,   
	tax.totalamount as TotalInvoiceAmount,
    Tax.CGST       As TotalCgstAmount,  
    Tax.SGST       As TotalSgstAmount,  
    Tax.IGST       As TotalIgstAmount,  
    0.00        As TotalCessAmount,  
   0.00        As TotalCessNonAdvolAmount,  
    Tax.taxable_amt      As TotalAssessableAmount,  
    Tax.OtherCharge      As OtherAmount,  
    Tax.TCS              As OtherTcsAmount,   
    Null        As TransId,  
   @carrier_name    As TransName,  
    'ROAD'   As TransMode,      
    --0         As Distance,   
	0     As Distance,
    Replace(t.tran_no,'/','')  As TransDocNo,  
    Convert(VarChar(10),  t.tran_date,103)    As TransDocDt,  
  
   @veh  As VehNo,   
  null    As VehType,  
  
      
    buyer.Regd_No				    As BuyerDtls_Gstin,  
    company_name     As BuyerDtls_LglNm,  
    company_name     As BuyerDtls_TrdNm,  
    buyer.Addr1      As BuyerDtls_Addr1,  
    buyer.Addr2      As BuyerDtls_Addr2,  
    buyer.Loc      As BuyerDtls_Loc,  
    buyer.Pin      As BuyerDtls_Pin,  
    left(tax.party_regd_no,2)      As BuyerDtls_Stcd,   
       
    Tax.own_regd_no      As SellerDtls_Gstin,  
    OuDet.company_name     As SellerDtls_LglNm,  
    OuDet.company_name     As SellerDtls_TrdNm,     
    Sell.Addr1       As SellerDtls_Addr1,  
    Sell.Addr2       As SellerDtls_Addr2,  
    Sell.Loc       As SellerDtls_Loc,  
    Sell.Pin       As SellerDtls_Pin,  
    Sell.TAX_REGION      As SellerDtls_Stcd,  
    company_name     As ExpShipDtls_LglNm,   
    buyer.Addr1       As ExpShipDtls_Addr1,  
    buyer.Addr2      As ExpShipDtls_Addr2,  
     buyer.Loc       As ExpShipDtls_Loc,  
    buyer.Pin      As ExpShipDtls_Pin,  
    left(tax.party_regd_no,2)     As ExpShipDtls_Stcd,  
    OuDet.company_name     As DispDtls_Nm,  
    OuDet.Addr1       As DispDtls_Addr1,  
    OuDet.Addr2       As DispDtls_Addr2,  
    OuDet.Loc  As DispDtls_Loc,  
    OuDet.Pin       As DispDtls_Pin,  
    Sell.TAX_REGION      As DispDtls_Stcd   
  from	scmdb..tcal_tran_hdr t(nolock) 
	Join	scmdb..tcal_tax_hdr h(nolock) 
	On		t.tran_no		=	h.tran_no	
	and		t.tran_type		=	h.tran_type
	and		t.tran_ou		=	h.tran_ou
	and		t.tax_type		=	h.tax_type
	and		t.tran_type		=	@TranType
    And     t.tran_no   =   @TranNo  
    And     t.tran_ou   =  @Ou  
    left Join zrit_Rmcl_eInvoice_Cust_Dtls  CustMst1  (Nolock)          
    On  t.supp_cust_code  =   CustMst1.Cust_Code         
    And  CustMst1.isBillTo  =   'Y'       
    Join dbo.zrit_Rmcl_eInvoice_Itm_Master Itm    (Nolock)          
    On	h.item_tc_usage_id   =   Itm.itm_itemcode  
    and	h.item_tc_variant	=	Itm.itm_variantcode
    Join dbo.zrit_Rmcl_eInvoice_Tax_Dtls      Tax     (Nolock )   
    On  t.tran_no   =   Tax.tran_no        
    And  t.tran_ou   =   Tax.tran_ou 
	and h.tran_line_no =Tax.tran_line_no /*code added by krishnan avoid duplication issue*/
	join Zrit_Rmcl_eInvoice_SellerDtls1 Sell (nolock)
	on    Tax.own_regd_no      =    Sell.Regd_No
	and t.company_code =Sell.Companycode
    and  t.tran_ou  =  Sell.ou
    join zrit_Rmcl_eInvoice_SellerDtls1 buyer (nolock)
    on tax.party_tax_region=buyer.TAX_REGION --added by nambirajan 
	and t.company_code =buyer.Companycode
    and  buyer.Ou =@buyer_ou    -- added by nambrajan 
Join zrit_Rmcl_eInvoice_OuAddress  OuDet (Nolock)         
    On  t.tran_ou   =   OuDet.OUInstId 
	/* code added by nambirajan starts here*/
JOIN scmdb..adisp_transfer_hdr HDR (NOLOCK)
ON  HDR.transfer_number =t.tran_no
and HDR.ou_id          =t.tran_ou

 Select t.tran_ou     As Ou,    
     t.tran_no     As TranNo,    
    t.tran_type        As TranType,   
  
    h.tran_line_no   As ItemList_ProdName,  
    itm_itemdesc      As ItemList_ProdDesc,   
    hsn_code       As ItemList_HsnCd,  
    isnull(h.quantity,1)      As ItemList_Qty,  
    'NOS'        As ItemList_Unit,  
    --StiDtl.stidtl_uom     As ItemList_Unit,  
    Tax.taxable_amt      As ItemList_AssAmt,  
    '0'         As ItemList_CgstRt,  
    --Tax.CGSTRate      As ItemList_CgstRt,  
    Tax.CGST       As ItemList_CgstAmt,      
    --Tax.SGSTRate      As ItemList_SgstRt,   
    '0'         As ItemList_SgstRt,    
    Tax.SGST       As ItemList_SgstAmt,   
    '0'         As ItemList_IgstRt,   
    --Tax.IGSTRate      As ItemList_IgstRt,    
    Tax.IGST     As ItemList_IgstAmt,  
    0.00        As ItemList_CesRt,  
    0.00        As ItemList_CesAmt,  
    0.00        As ItemList_OthChrg,  
    0.00        As ItemList_CesNonAdvAmt  

	from	scmdb..tcal_tran_hdr t(nolock)
	Join	scmdb..tcal_tax_hdr h(nolock) 
	On		t.tran_no		=	h.tran_no	
	and		t.tran_type		=	h.tran_type
	and		t.tran_ou		=	h.tran_ou
	and		t.tax_type		=	h.tax_type
	and		t.tran_type		=   @TranType
    And  t.tran_no   =  @TranNo      
    And  t.tran_ou   =   @Ou   
  Join   dbo.Zrit_Rmcl_eInvoice_Itm_Master1 Itm    (Nolock)          
  On	 h.item_tc_usage_id =   Itm.itm_itemcode  
  and	 h.item_tc_variant	=	Itm.itm_variantcode
  Join   dbo.zrit_Rmcl_eInvoice_Tax_Dtls      Tax  (Nolock)            
  On     t.tran_no   =   Tax.tran_no        
  And    t.tran_ou   =   Tax.tran_ou       
  and    h.tran_line_no=Tax.tran_line_no
  --And    Tax.taxable_amt >   0.0   /*code commented by krishnan zero value asset also send to portal*/     



end


End 
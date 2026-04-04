using System;
using System.IO;
using System.Windows;

namespace BinaryBloomClock.Windows;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        var indexPath = Path.Combine(AppContext.BaseDirectory, "web", "index.html");

        if (!File.Exists(indexPath))
        {
            MessageBox.Show($"Missing web assets at: {indexPath}", "Binary Bloom Clock", MessageBoxButton.OK, MessageBoxImage.Error);
            return;
        }

        await ClockWebView.EnsureCoreWebView2Async();
        ClockWebView.Source = new Uri(indexPath);
    }
}

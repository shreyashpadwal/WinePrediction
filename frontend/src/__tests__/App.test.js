  render(<App />);
  const linkElement = screen.getByText(/wine quality/i);
  expect(linkElement).toBeInTheDocument();
});
